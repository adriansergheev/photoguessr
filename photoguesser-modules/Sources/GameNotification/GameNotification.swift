import SwiftUI
import Styleguide
import ComposableArchitecture

public struct GameNotification: ReducerProtocol {
	public struct State: Equatable {
		var text: String
		var timerIsActive: Bool = false

		public init(text: String) {
			self.text = text
		}
	}

	public enum Action {
		case onAppear
		case didExpire
	}

	@Dependency(\.continuousClock) var clock
	private enum TimerID {}

	public init() {}

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
			state.timerIsActive = false
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
				HStack(spacing: .grid(4)) {
					Image(systemName: "crown")
						.foregroundColor(.adaptiveBlack)
					Text(viewStore.text)
						.font(.system(size: 17))
						.foregroundColor(.adaptiveBlack)
						.bold()
					Image(systemName: "crown")
						.foregroundColor(.adaptiveBlack)
				}
			}
			.padding(.grid(2))
			.background(Color.photoGuesserGold.opacity(0.7))
			.cornerRadius(4)
			.overlay {
				RoundedRectangle(cornerRadius: 10)
					.stroke(Color.adaptiveBlack, lineWidth: 0.5)
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
				initialState: .init(text: "You nailed it!"),
				reducer: GameNotification()
			)
		)
	}
}
#endif
