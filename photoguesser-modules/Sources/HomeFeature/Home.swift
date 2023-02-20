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
	}

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
				state.gameInstance = .init()
				return .none
			case .onPlayLimitedTap:
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
	let store: StoreOf<Home>

	public init(store: StoreOf<Home>) {
		self.store = store
	}

	public var body: some View {
		WithViewStore(self.store) { viewStore in
			VStack(alignment: .center) {
				IfLetStore(self.store.scope(state: \.gameInstance, action: Home.Action.game)) { store in
					GameView(store: store)
				} else: {
					VStack(spacing: 8) {
						Button {
							viewStore.send(.onPlayUnlimitedTap)
						} label: {
							Text("Play Unlimited")
						}
						Button {
							viewStore.send(.onPlayLimitedTap)
						} label: {
							Text("Play Out of 10")
						}
					}
				}
			}
		}
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
