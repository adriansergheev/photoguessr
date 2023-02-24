import SwiftUI
import Styleguide
import ComposableArchitecture

public struct GameOver: ReducerProtocol {

	public struct State: Equatable {
//		var score: Int
//		public init(score: Int = 0) {
//			self.score = score
//		}
		public init() {}
	}

	public enum Action: Equatable {
		case onCloseButtonTapped
	}

	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Reduce { _, action in
			switch action {
			case .onCloseButtonTapped:
				return .none
			}
		}
	}
}

public struct GameOverView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.adaptiveSize) var adaptiveSize
	public let store: StoreOf<GameOver>

	public init(store: StoreOf<GameOver>) {
		self.store = store
	}

	public var body: some View {
		WithViewStore(self.store) { viewStore in
			ScrollView(showsIndicators: false) {
				VStack(spacing: self.adaptiveSize.pad(24)) {
					HStack {
						Spacer()
						Button(action: { viewStore.send(.onCloseButtonTapped, animation: .default) }) {
							Image(systemName: "xmark")
						}
					}
					.font(.system(size: 24))
					.padding()

					Text("🔫")
						.font(.system(size: 30))
						.multilineTextAlignment(.center)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

				Spacer()

				VStack(spacing: .grid(8)) {
					Divider()

					Text("Enjoying\nthe game?")
						.font(.system(size: 30))
						.multilineTextAlignment(.center)

					Button(action: {
						//
					}) {
						Text("Share with a friend")
					}
					.buttonStyle(
						ActionButtonStyle(
							backgroundColor: self.colorScheme == .dark ? .photoGuesserCream : .black,
							foregroundColor: self.colorScheme == .dark ? .black : .photoGuesserCream
						)
					)
					.padding(.bottom, .grid(0))
				}
				.padding(.vertical, .grid(12))
			}
			.foregroundColor(self.colorScheme == .dark ? .photoGuesserCream : .black)
			.background(
				(self.colorScheme == .dark ? .black : Color.photoGuesserCream)
					.ignoresSafeArea()
			)
		}
	}
}

#if DEBUG
struct GameOverView_Previews: PreviewProvider {
	static var previews: some View {
		GameOverView(
			store: .init(
				initialState: .init(),
				reducer: GameOver()
			)
		)
	}
}
#endif
