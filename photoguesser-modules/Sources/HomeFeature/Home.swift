import SwiftUI
import Styleguide
import GameFeature
import Dependencies
import SharedModels
import StorageClient
import CitiesFeature
import LocationClient
import MenuBackground
import ComposableArchitecture

public struct Home: ReducerProtocol {
	public struct State: Equatable {
		var gameInstance: Game.State?
		var menuBackground = MenuBackground.State()
		var _isLoading: Bool = false

		var alert: AlertState<Action.Alert>?
		@PresentationState public var cities: CitiesFeature.State?

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

	@Dependency(\.locationClient) var locationClient
	@Dependency(\.userDefaults) var userDefaultsClient
	@Dependency(\.storageClient) var storageClient
	public init() {}

	func startGame(_ state: inout State, gameLocation: GameLocation) {
		state.gameInstance = .init(gameLocation: gameLocation)
		state._isLoading = false
		try? saveGameLocation(gameLocation)
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
						self.startGame(&state, gameLocation: (try loadGameLocation()))
						// figure out if this has to execute even if the try above throws
						return .fireAndForget { @MainActor  [authorizationStatus = locationClient.authorizationStatus] in
							switch authorizationStatus {
							 case .denied, .restricted:
								 await userDefaultsClient.setNotSharingLocationPreference(true)
							 case .authorizedAlways, .authorizedWhenInUse:
								 await userDefaultsClient.setNotSharingLocationPreference(false)
							 case .notDetermined: break
							 @unknown default: break
							 }
						 }
					} catch {
						switch locationClient.authorizationStatus {
						case .notDetermined:
							if userDefaultsClient.isNotWillingToShareLocation {
								state.cities = .init()
								return .none
							}

							state.alert = AlertState {
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
					print("Present cities")
					return .none
				case .tap(.onSettings):
					print("Present settings")
					return .none
				case .game(.gameNavigationBar):
					return .none
				case .game(.gameOver(.delegate(.close))):
					state.gameInstance = nil
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
						await userDefaultsClient.setNotSharingLocationPreference(true)
					}
				case .alert(.okToUseLocation):
					// TODO: perhaps "search bar" in the "cities" list?
					locationClient.requestWhenInUseAuthorization()
					locationClient.requestLocation()
					state._isLoading = true
					return .run { send in
						for await delegateEvent in locationClient.delegate {
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
								if case let .success(placemarks) = await locationClient.reverseGeocodeLocation(location) {
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
				}
			}
			.ifLet(\.gameInstance, action: /Action.game) {
				Game()
			}
			.ifLet(\.$cities, action: /Action.cities) {
				CitiesFeature()
			}
		}
	}
}

extension Home {
	func hasSavedGameLocation() -> Bool {
		do {
			_ = try loadGameLocation()
			return true
		} catch {
			return false
		}
	}

	func loadGameLocation() throws -> GameLocation {
		try JSONDecoder().decode(
			GameLocation.self,
			from: storageClient.load(.gameLocation)
		)
	}

	func saveGameLocation(_ gameLocation: GameLocation) throws {
		try storageClient.save(
			JSONEncoder().encode(gameLocation),
			.gameLocation
		)
	}
}

public struct HomeView: View {
	@Environment(\.colorScheme) var colorScheme
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
						Text("Photoguesser")
							.font(.system(.largeTitle))
							.bold()
						HomeButton {
							viewStore.send(.tap(.onPlay))
						} content: {
							HomeButtonContent(
								image: Image(systemName: "photo.stack.fill"),
								imagePadding: .grid(12),
								text: Text("Play")
							)
						}
						HomeButton {
							viewStore.send(.tap(.onCities))
						} content: {
							HomeButtonContent(
								image: Image(systemName: "building.columns"),
								imagePadding: .grid(12),
								text: Text("Cities")
							)
						}
						HStack {
							HomeButton {
								viewStore.send(.tap(.onLeaderboards))
							} content: {
								HomeButtonContent(
									image: Image(systemName: "star.leadinghalf.filled"),
									text: Text("Leaderboards")
								)
								.opacity(0.5)
								.disabled(true)
							}
							HomeButton {
								viewStore.send(.tap(.onSettings))
							} content: {
								HomeButtonContent(
									image: Image(systemName: "gearshape"),
									text: Text("Settings")
								)
								.opacity(0.5)
								.disabled(true)
							}
						}
					}
					.padding(.grid(16))
					.foregroundColor(self.colorScheme == .light ? .photoGuesserCream : .black)
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
					.alert(
						self.store.scope(state: \.alert, action: Home.Action.alert),
						dismiss: Home.Action.Alert.dismiss
					)
				}
			}
		}
		.sheet(
			store: self.store.scope(state: \.$cities, action: Home.Action.cities)
		) { store in
			Cities(store: store)
		}
//		.modifier(DeviceStateModifier())
	}
}

extension URL {
	fileprivate static let gameLocation = Self.documentsDirectory
		.appending(component: "gameLocation.json")
}

struct HomeButtonContent: View {
	@Environment(\.colorScheme) var colorScheme

	let image: Image
	let imagePadding: CGFloat
	let text: Text

	init(
		image: Image,
		imagePadding: CGFloat = .grid(9),
		text: Text
	) {
		self.image = image
		self.imagePadding = imagePadding
		self.text = text
	}

	var body: some View {
		ZStack {
			image
				.resizable()
				.aspectRatio(contentMode: .fit)
				.padding(.all, self.imagePadding)
				.foregroundColor(.adaptiveBlack)
			VStack {
				Spacer()
				text
					.font(.callout)
					.bold()
					.padding([.top, .bottom], .grid(1))
					.frame(maxWidth: .infinity)
					.foregroundColor(self.colorScheme == .dark ? .black : .photoGuesserCream)
					.background(self.colorScheme == .dark ? Color.photoGuesserCream : .black)
					.adaptiveCornerRadius([.bottomLeft, .bottomRight], 13)
			}
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
			.font(.system(size: 20))
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
					initialState: .init(gameInstance: .init(mode: .limited(max: 3, current: 0))),
					reducer: Home()
				)
			)
		}
	}
}
#endif
