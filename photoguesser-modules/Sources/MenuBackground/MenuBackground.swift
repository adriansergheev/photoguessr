// import NukeUI
import SwiftUI
import Styleguide
// import ApiClientLive
import ComposableArchitecture

//let demoImage = Image(uiImage: UIImage(named: "demo", in: Bundle.module, with: nil)!)
let demoImage2 = Image(uiImage: UIImage(named: "demo2", in: Bundle.module, with: nil)!)
let demoImage3 = Image(uiImage: UIImage(named: "demo3", in: Bundle.module, with: nil)!)
let demoImage4 = Image(uiImage: UIImage(named: "demo4", in: Bundle.module, with: nil)!)
let demoImage5 = Image(uiImage: UIImage(named: "demo5", in: Bundle.module, with: nil)!)

public struct MenuBackground: ReducerProtocol {
	public struct State: Equatable {
		public var demoImages: [Image]
		public var backgroundImage: Image
		public var timerTicks: Int = 0
		public var isTimerActive: Bool = false
		
		public init() {
			demoImages = [
				//				demoImage,
				demoImage2,
				demoImage3,
				demoImage4,
				demoImage5
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
	private enum TimerID {}
	public init() { }

	public var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
			switch action {
			case .onAppear:
				state.isTimerActive = true
				return .run { [isTimerActive = state.isTimerActive] send in
					guard isTimerActive else { return }
					for await _ in self.clock.timer(interval: .seconds(5)) {
						await send(.timerTicked, animation: .interpolatingSpring(stiffness: 3000, damping: 40))
					}
				}
				.cancellable(id: TimerID.self, cancelInFlight: true)
			case .onDisappear:
				state.isTimerActive = false
				return .cancel(id: TimerID.self)
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
		WithViewStore(self.store) { viewStore in
			viewStore.backgroundImage
				.resizable()
				.aspectRatio(contentMode: .fill)
				.ignoresSafeArea()
				.animation(.easeIn(duration: 3), value: viewStore.backgroundImage)
				.onAppear { viewStore.send(.onAppear) }
				.onDisappear { viewStore.send(.onDisappear) }
		}
	}
}

struct MenuBackgroundView_Previews: PreviewProvider {
	static var previews: some View {
		MenuBackgroundView(
			store: .init(
				initialState: .init(),
				reducer: MenuBackground()
			)
		)
	}
}
