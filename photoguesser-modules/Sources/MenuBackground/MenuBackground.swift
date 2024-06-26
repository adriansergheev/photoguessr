import SwiftUI
import Styleguide
import ComposableArchitecture

let demoImage = Image(uiImage: UIImage(named: "demo", in: Bundle.module, with: nil)!)
let demoImage2 = Image(uiImage: UIImage(named: "demo2", in: Bundle.module, with: nil)!)
let demoImage3 = Image(uiImage: UIImage(named: "demo3", in: Bundle.module, with: nil)!)

public struct MenuBackground: ReducerProtocol {
	public struct State: Equatable {
		public var demoImages: [Image]
		public var backgroundImage: Image
		public var timerTicks: Int = 0
		public var isTimerActive: Bool = false

		public init() {
			demoImages = [
				demoImage,
				demoImage2,
				demoImage3,
			]
			backgroundImage = demoImages.randomElement()!
		}
	}
	public enum Action: Equatable {
		case onAppear
		case onDisappear
		case timerTicked
	}

	@Dependency(\.continuousClock) var clock
	private enum TimerID: Hashable {
		case timer
	}
	public init() { }

	public var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
			switch action {
			case .onAppear:
				state.isTimerActive = true
				return .run { [isTimerActive = state.isTimerActive] send in
					guard isTimerActive else { return }
					for await _ in self.clock.timer(interval: .seconds(10)) {
						await send(.timerTicked, animation: .easeIn(duration: 3))
					}
				}
				.cancellable(id: TimerID.timer, cancelInFlight: true)
			case .onDisappear:
				state.isTimerActive = false
				return .cancel(id: TimerID.timer)
			case .timerTicked:
				state.timerTicks += 1
				// FIXME: if no connection, show demo images.
				state.backgroundImage = state.demoImages.randomElement()!
				return .none
			}
		}
	}
}

public struct MenuBackgroundView: View {
	@Environment(\.colorScheme) var colorScheme
	public let store: StoreOf<MenuBackground>

	public init(store: StoreOf<MenuBackground>) {
		self.store = store
	}

	public var body: some View {
		WithViewStore(self.store, observe: {$0.backgroundImage}) { viewStore in
			viewStore.state
				.resizable()
				.aspectRatio(contentMode: .fill)
				.ignoresSafeArea()
				.onAppear { viewStore.send(.onAppear) }
				.onDisappear { viewStore.send(.onDisappear) }
		}
	}
}

#if DEBUG
struct MenuBackgroundView_Previews: PreviewProvider {
	static var previews: some View {
		Preview {
			MenuBackgroundView(
				store: .init(
					initialState: .init(),
					reducer: MenuBackground()
				)
			)
		}
	}
}
#endif
