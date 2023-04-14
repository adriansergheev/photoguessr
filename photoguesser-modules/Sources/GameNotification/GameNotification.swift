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

	public var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
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
}

public struct GameNotificationView: View {
	public let store: StoreOf<GameNotification>

	public init(store: StoreOf<GameNotification>) {
		self.store = store
	}

	public var body: some View {
		WithViewStore(self.store, observe: { $0 }) { viewStore in
			VStack(alignment: .leading) {
				HStack(spacing: .grid(4)) {
					Image(systemName: "crown")
						.foregroundColor(.black)
					Text(viewStore.text)
						.adaptiveFont(.cormorantBold, size: 18)
						.foregroundColor(.black)
					Image(systemName: "crown")
						.foregroundColor(.black)
				}
			}
			.padding(.grid(2))
			.background(Color.photoGuesserGold.opacity(0.7))
			.cornerRadius(4)
			.overlay {
				RoundedRectangle(cornerRadius: 10)
					.stroke(Color.adaptiveBlack, lineWidth: 0.5)
			}
			.onAppear { viewStore.send(.onAppear) }
		}
	}
}

#if DEBUG
struct GameNotification_Previews: PreviewProvider {
	static var previews: some View {
		Preview {
			GameNotificationView(
				store: .init(
				initialState: .init(text: "Photo was taken between \(0) and \(0)\n\(0) points!"),
					reducer: GameNotification()
				)
			)
		}
	}
}
#endif
