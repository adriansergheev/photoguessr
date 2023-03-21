import SwiftUI
import Styleguide
import GameFeature
import Dependencies
import CitiesFeature
import MenuBackground
import LocationClientLive
import ComposableArchitecture

public struct Home: ReducerProtocol {
	public struct State: Equatable {
		public var gameInstance: Game.State?
		public var menuBackground = MenuBackground.State()
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
		case onPlayTap
		case onCitiesTap
		case onLeaderboardsTap
		case onSettingsTap

		case game(Game.Action)
		case menuBackground(MenuBackground.Action)
		case cities(PresentationAction<CitiesFeature.Action>)
	}

	@Dependency (\.locationClient) var locationClient
	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		CombineReducers {
			Scope(state: \State.menuBackground, action: /Action.menuBackground) {
				MenuBackground()
			}
			Reduce { state, action in
				switch action {
				case .onPlayTap:
					state.gameInstance = .init()
					return .none
				case .onCitiesTap:
					state.cities = .init()
					return .none
				case .onLeaderboardsTap:
					print("Present cities")
					return .none
				case .onSettingsTap:
					print("Present Settings")
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
					state.gameInstance = .init(gameLocation: gameLocation)
					return .none
				case .cities:
					return .none
				}
			}
			.ifLet(\.gameInstance, action: /Action.game) {
				Game()
			}
			.ifLet(\.$cities, action: /Action.cities) {
				CitiesFeature()
					._printChanges()
			}
		}
	}
}

public struct HomeView: View {
	@Environment(\.colorScheme) var colorScheme
	let store: StoreOf<Home>
	@ObservedObject var viewStore: ViewStore<Void, Home.Action>

	public init(store: StoreOf<Home>) {
		self.store = store
		self.viewStore = ViewStore(self.store.stateless)
	}

	public var body: some View {
		VStack(alignment: .center) {
			IfLetStore(self.store.scope(state: \.gameInstance, action: Home.Action.game)) { store in
				GameView(store: store)
			} else: {
				VStack {
					Text("Photoguesser")
						.font(.system(.largeTitle))
						.bold()
					HomeButton {
						viewStore.send(.onPlayTap)
					} content: {
						HomeButtonContent(
							image: Image(systemName: "photo.stack.fill"),
							imagePadding: .grid(12),
							text: Text("Play")
						)
					}
					HomeButton {
						viewStore.send(.onCitiesTap)
					} content: {
						HomeButtonContent(
							image: Image(systemName: "building.columns"),
							imagePadding: .grid(12),
							text: Text("Cities")
						)
					}
					HStack {
						HomeButton {
							viewStore.send(.onLeaderboardsTap)
						} content: {
							HomeButtonContent(
								image: Image(systemName: "star.leadinghalf.filled"),
								text: Text("Leaderboards")
							)
							.opacity(0.5)
							.disabled(true)
						}
						HomeButton {
							viewStore.send(.onSettingsTap)
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
