import SwiftUI
import GameFeature
import ComposableArchitecture
import Styleguide

public struct Home: ReducerProtocol {
	
	public struct State: Equatable {
		public var gameInstance: Game.State?
		
		public init(gameInstance: Game.State? = nil) {
			self.gameInstance = gameInstance
		}
	}g
	
	public enum Action: Equatable {
		case onPlayUnlimitedTap
		case onPlayLimitedTap
		
		case game(Game.Action)
	}
	
	public init() {}
	
	public var body: some ReducerProtocol<State, Action> {
		return Reduce { state, action in
			switch action {
			case .onPlayUnlimitedTap:
				state.gameInstance = .init(mode: .unlimited)
				return .none
			case .onPlayLimitedTap:
				state.gameInstance = .init(mode: .limited(max: 10, current: 0))
				return .none
			case .game(.gameNavigationBar(.onSettingsTap)):
				state.gameInstance = nil
				return .none
			case .game:
				return .none
			}
		}
		.ifLet(\.gameInstance, action: /Action.game) {
			Game()
		}
	}
}

public struct HomeView: View {
	@Environment(\.colorScheme) var colorScheme
	let store: StoreOf<Home>
	@ObservedObject var viewStore: ViewStore<Home.State, Home.Action>
	
	public init(store: StoreOf<Home>) {
		self.store = store
		self.viewStore = ViewStore(self.store)
	}
	
	public var body: some View {
		VStack(alignment: .center) {
			IfLetStore(self.store.scope(state: \.gameInstance, action: Home.Action.game)) { store in
				GameView(store: store)
			} else: {
				VStack {
					
					Button {
						viewStore.send(.onPlayLimitedTap)
					} label: {
						VStack(alignment: .center) {
							Text("Play Out of 10")
								.padding(.all, .grid(3))
								.font(.system(size: 16))
								.foregroundColor(.adaptiveWhite)
						}
					}
					.buttonStyle(
						HomeButtonStyle(
							backgroundColor: self.colorScheme == .dark ? .photoGuesserCream : .black,
							foregroundColor: self.colorScheme == .dark ? .black : .photoGuesserCream
						)
					)
					HStack {
						Button {
							viewStore.send(.onPlayUnlimitedTap)
						} label: {
							VStack(alignment: .center) {
								Image(systemName: "infinity.circle")
									.padding(.all, .grid(3))
									.foregroundColor(.adaptiveWhite)
							}
						}
						.buttonStyle(
							HomeButtonStyle(
								backgroundColor: self.colorScheme == .dark ? .photoGuesserCream : .black,
								foregroundColor: self.colorScheme == .dark ? .black : .photoGuesserCream
							)
						)
						VStack {
							Rectangle()
								.border(.red)
							Rectangle()
								.border(.red)
						}
					}
				}
				.padding(.grid(16))
				.foregroundColor(self.colorScheme == .dark ? .photoGuesserCream : .black)
				.background(
					(self.colorScheme == .dark ? .black : Color.photoGuesserCream)
						.ignoresSafeArea()
				)
			}
		}
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
		HomeView(
			store: .init(
				initialState: .init(),
				reducer: Home()
			)
		)
	}
}
#endif
