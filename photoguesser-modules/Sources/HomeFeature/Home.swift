import SwiftUI
import Styleguide
import GameFeature
import Dependencies
import SharedModels
import StorageClient
import CitiesFeature
import LocationClient
import MenuBackground
import SettingsFeature
import ComposableGameCenter
import ComposableArchitecture

public struct Home: ReducerProtocol {
	public struct State: Equatable {
		var gameInstance: Game.State?
		var menuBackground = MenuBackground.State()
		var _isLoading = false
		var _isLocationFeatureEnabled = false

		var alert: AlertState<Action.Alert>?
		@PresentationState var cities: CitiesFeature.State?
		@PresentationState var settings: SettingsFeature.State?

		public init(
			gameInstance: Game.State? = nil,
			menuBackground: MenuBackground.State = MenuBackground.State()
		) {
			self.gameInstance = gameInstance
			self.menuBackground = menuBackground
		}
	}

	public enum Action: Equatable {
		case tap(Tap)
		case game(Game.Action)
		case location(Location)
		case menuBackground(MenuBackground.Action)
		case cities(PresentationAction<CitiesFeature.Action>)
		case settings(PresentationAction<SettingsFeature.Action>)
		case alert(Alert)

		public enum Alert {
			case dismiss
			case deny
			case okToUseLocation
		}

		public enum Location: Equatable {
			case locationChanged(GameLocation?)
		}

		public enum Tap {
			case onPlay
			case onCities
			case onLeaderboards
			case onSettings
		}
	}

	@Dependency(\.location) var location
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.storage) var storage
	@Dependency(\.gameCenter) var gameCenter
	public init() {}

	func startGame(_ state: inout State, gameLocation: GameLocation) {
		state.gameInstance = .init(gameLocation: gameLocation)
		state._isLoading = false
		try? self.storage.saveGame(gameLocation)
	}

	public var body: some ReducerProtocol<State, Action> {
		CombineReducers {
			Scope(state: \State.menuBackground, action: /Action.menuBackground) {
				MenuBackground()
			}
			Reduce { state, action in
				switch action {
				case .tap(.onPlay):
					do {
						// figure out if this has to execute even if the try throws
						self.startGame(&state, gameLocation: (try self.storage.loadGame()))
						if !state._isLocationFeatureEnabled { return .none }
						return .fireAndForget { @MainActor  [authorizationStatus = location.authorizationStatus] in
							switch authorizationStatus {
							case .denied, .restricted:
								await userDefaults.setNotSharingLocationPreference(true)
							case .authorizedAlways, .authorizedWhenInUse:
								await userDefaults.setNotSharingLocationPreference(false)
							case .notDetermined: break
							@unknown default: break
							}
						}
					} catch {
						if !state._isLocationFeatureEnabled {
							state.cities = .init()
							return .none
						}

						switch location.authorizationStatus {
						case .notDetermined:
							if userDefaults.isNotWillingToShareLocation {
								state.cities = .init()
								return .none
							}

							state.alert = .accessLocation()
						default: break
						}
						return .none
					}

				case .tap(.onCities):
					// ignore more than one location events
					if state.cities == nil {
						state.cities = .init()
					}
					return .none
				case .tap(.onLeaderboards):
					return .fireAndForget {
						await gameCenter.gameCenterViewController.present()
						await gameCenter.gameCenterViewController.dismiss()
					}
				case .tap(.onSettings):
					state.settings = .init()
					return .none
				case .game(.gameNavigationBar):
					return .none
				case .game(.delegate(.close)):
					state.gameInstance = nil
					return .none
				case .game:
					return .none
				case .menuBackground:
					return .none
				case .cities(.presented(.delegate(.close))):
					state.cities = nil
					return .none
				case let .cities(.presented(.delegate(.startGame(gameLocation)))):
					state.cities = nil
					self.startGame(&state, gameLocation: gameLocation)
					return .none
				case .cities:
					return .none
				case .alert(.dismiss):
					state.alert = nil
					return .none
				case .alert(.deny):
					state.cities = .init()
					return .fireAndForget {
						await userDefaults.setNotSharingLocationPreference(true)
					}
				case .alert(.okToUseLocation):
					// TODO: perhaps "search bar" in the "cities" list?
					location.requestWhenInUseAuthorization()
					location.requestLocation()
					state._isLoading = true
					return .run { send in
						for await delegateEvent in self.location.delegate {
							switch delegateEvent {
							case let .didChangeAuthorization(authorization):
								switch authorization {
								case .authorizedAlways, .authorizedWhenInUse: break
								case .denied, .notDetermined, .restricted:
									await send(.location(.locationChanged(nil)))
									return
								@unknown default: break
								}
							case let .didUpdateLocations(locations):
								guard let location = locations.first else {
									await send(.location(.locationChanged(nil)))
									return
								}
								if case let .success(placemarks) = await self.location.reverseGeocodeLocation(location) {
									let name = placemarks.first?.name ?? placemarks.first?.locality ?? ""
									let gameLocation = GameLocation(
										location: .init(lat: location.coordinate.latitude, long: location.coordinate.longitude),
										name: name
									)
									await send(.location(.locationChanged(gameLocation)))
								}
							case .didFailWithError: break
							}
						}
					}
				case let .location(.locationChanged(gameLocation)):
					// ignore more than one location events
					if let gameLocation, state.gameInstance == nil {
						self.startGame(&state, gameLocation: gameLocation)
					} else if state.cities == nil {
						state.cities = .init()
					}
					return .none
				case .settings(.presented(.delegate(.close))):
					state.settings = nil
					return .none
				case .settings:
					return .none
				}
			}
			.ifLet(\.gameInstance, action: /Action.game) {
				Game()
			}
			.ifLet(\.$cities, action: /Action.cities) {
				CitiesFeature()
			}
			.ifLet(\.$settings, action: /Action.settings) {
				SettingsFeature()
			}
		}
	}
}

extension AlertState where Action == Home.Action.Alert {
	static func accessLocation() -> Self {
		AlertState {
			TextState("Play with nearby photos?")
		} actions: {
			ButtonState(action: .okToUseLocation) {
				TextState("Sure!")
			}
			ButtonState(action: .deny) {
				TextState("Let me select the location")
			}
			ButtonState(role: .cancel, action: .dismiss) {
				TextState("Disimss")
			}
		} message: {
			TextState("View nearby historical photos")
		}
	}
}

public struct HomeView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.deviceState) var deviceState
	let store: StoreOf<Home>
	@ObservedObject var viewStore: ViewStore<Bool, Home.Action>

	public init(store: StoreOf<Home>) {
		self.store = store
		self.viewStore = ViewStore(self.store, observe: { $0._isLoading })
	}

	public var body: some View {
		VStack(alignment: .center) {
			IfLetStore(self.store.scope(state: \.gameInstance, action: Home.Action.game)) { store in
				GameView(store: store)
			} else: {
				ZStack {
					if viewStore.state {
						ProgressView()
							.zIndex(1)
					}
					VStack {
						Text("photoguessr")
							.adaptiveFont(.cormorantBold, size: 34)
						HomeButton {
							viewStore.send(.tap(.onPlay))
						} content: {
							HomeButtonContent(
								image: Image(systemName: "gamecontroller"),
								text: Text("Play")
							)
						}
						HomeButton {
							viewStore.send(.tap(.onCities))
						} content: {
							HomeButtonContent(
								image: Image(systemName: "building.columns"),
								text: Text("Cities")
							)
						}
						HomeButton {
							viewStore.send(.tap(.onLeaderboards))
						} content: {
							HomeButtonContent(
								image: Image(systemName: "star.leadinghalf.filled"),
								text: Text("Leaderboards")
							)
						}
						HomeButton {
							viewStore.send(.tap(.onSettings))
						} content: {
							HomeButtonContent(
								image: Image(systemName: "gearshape"),
								text: Text("Settings")
							)
						}
					}
					.padding([.leading, .trailing], .grid(16))
					.padding([.top, .bottom], .grid(54))
					.frame(
						maxWidth: self.deviceState.idiom == .pad ? UIScreen.width / 1.5 : .infinity,
						maxHeight:  self.deviceState.idiom == .pad ? UIScreen.width / 1 : .infinity
					)
					.foregroundColor(self.colorScheme == .light ? .photoGuesserCream : .black)
					.alert(
						self.store.scope(state: \.alert, action: Home.Action.alert),
						dismiss: Home.Action.Alert.dismiss
					)
					Color.clear
						.background(
							(self.colorScheme == .light ? .black.opacity(0.5) : Color.black.opacity(0.1))
								.ignoresSafeArea()
								.background(
									MenuBackgroundView(
										store: self.store.scope(
											state: \.menuBackground,
											action: Home.Action.menuBackground
										)
									)
								)
						)
						.zIndex(-1)
				}
			}
		}
		.sheet(
			store: self.store.scope(state: \.$cities, action: Home.Action.cities)
		) { store in
			Cities(store: store)
		}
		.sheet(
			store: self.store.scope(state: \.$settings, action: Home.Action.settings)
		) { store in
			Settings(store: store)
		}
		.modifier(DeviceStateModifier())
	}
}

struct HomeButtonContent: View {
	@Environment(\.colorScheme) var colorScheme

	let image: Image
	let text: Text

	var body: some View {
		HStack {
			image
				.aspectRatio(contentMode: .fit)
				.frame(width: 48, height: 48)
				.padding([.leading, .top, .bottom], .grid(2))
				.foregroundColor(self.colorScheme == .dark ? .photoGuesserCream : .photoGuesserBlack)
			text
				.adaptiveFont(.cormorantBold, size: 16)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.foregroundColor(self.colorScheme == .dark ? .black : .photoGuesserCream)
				.background(self.colorScheme == .dark ? Color.photoGuesserCream : .black)
				.adaptiveCornerRadius([.bottomRight, .topRight], 13)

		}
	}
}

struct HomeButton<Content: View>: View {
	@Environment(\.colorScheme) var colorScheme

	var buttonAction: (() -> Void)?
	var content: () -> Content

	init(
		buttonAction: (() -> Void)? = nil,
		@ViewBuilder content: @escaping () -> Content
	) {
		self.buttonAction = buttonAction
		self.content = content
	}

	var body: some View {
		Button {
			self.buttonAction?()
		} label: {
			content()
		}
		.buttonStyle(
			HomeButtonStyle(
				backgroundColor: self.colorScheme == .light ? .photoGuesserCream : .black,
				foregroundColor: self.colorScheme == .light ? .black : .photoGuesserCream
			)
		)
		.opacity(0.9)
	}
}

struct HomeButtonStyle: ButtonStyle {
	let backgroundColor: Color
	let foregroundColor: Color

	init(
		backgroundColor: Color,
		foregroundColor: Color
	) {
		self.backgroundColor = backgroundColor
		self.foregroundColor = foregroundColor
	}

	func makeBody(configuration: Configuration) -> some View {
		return configuration.label
			.foregroundColor(
				self.foregroundColor
					.opacity(configuration.isPressed ? 0.9 : 1)
			)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.adaptiveFont(.cormorantMedium, size: 20)
			.background(
				RoundedRectangle(cornerRadius: 13)
					.fill(
						self.backgroundColor
							.opacity(configuration.isPressed ? 0.5 : 1)
					)
			)
			.scaleEffect(configuration.isPressed ? 0.95 : 1.0)
	}
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		Preview {
			HomeView(
				store: .init(
					initialState: .init(),
					reducer: Home()
				)
			)
			//			HomeView(
			//				store: .init(
			//					initialState: .init(
			//						gameInstance: .init(
			//							mode: .limited(max: 3, current: 0),
			//							gameLocation: .init(location: .init(lat: 55.67594, long: 12.56553), name: "Copenhagen")
			//						)
			//					),
			//					reducer: Home()
			//				)
			//			)
		}
	}
}
#endif
