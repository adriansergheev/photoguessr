import SwiftUI
import Styleguide
import ComposableArchitecture

public struct GameNotification: ReducerProtocol {
	public struct State: Equatable {
		var pointsGained: Int
		var timerIsActive: Bool = false
		var didExpire: Bool = false

		public init(pointsGained: Int) {
			self.pointsGained = pointsGained
		}
	}

	public enum Action {
		case onAppear
		case didExpire
	}

	@Dependency(\.continuousClock) var clock
	private enum TimerID {}

	init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .onAppear:
			state.timerIsActive = true

			return .run { send in
				for await _ in self.clock.timer(interval: .seconds(5)) {
					await send(.didExpire, animation: .default)
				}
			}
			.cancellable(id: TimerID.self, cancelInFlight: true)
		case .didExpire:
			state.didExpire = true
			return .cancel(id: TimerID.self)
		}
	}
}

public struct GameNotificationView: View {
	public let store: StoreOf<GameNotification>

	public init(store: StoreOf<GameNotification>) {
		self.store = store
	}

	public var body: some View {
		WithViewStore(self.store) { viewStore in
			VStack(alignment: .leading) {
				VStack(alignment: .leading) {
					HStack(spacing: .grid(4)) {
						//						if viewStore.didExpire {
						//						}
						Image(systemName: "crown")
							.foregroundColor(Color.white)
						Text("You received \(viewStore.pointsGained)")
							.font(.system(size: 16))
							.foregroundColor(Color.white)
					}
				}
				.padding([.top, .bottom], .grid(3))
				.padding([.leading, .trailing], .grid(4))
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(Color.photoGuesserCream.opacity(0.7))
				.padding([.leading, .trailing], .grid(4))
			}
			.onAppear {
				viewStore.send(.onAppear)
			}
		}
	}
}

#if DEBUG
struct GameNotification_Previews: PreviewProvider {
	static var previews: some View {
		GameNotificationView(
			store: .init(
				initialState: .init(pointsGained: 42),
				reducer: GameNotification()
			)
		)
	}
}
#endif
