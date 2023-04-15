import SwiftUI
import Styleguide
import Dependencies
import ComposableGameCenter
import ComposableArchitecture

public struct GameOver: ReducerProtocol {
	public struct State: Equatable {
		public var score: Int
		var didReportScore = false
		public init(score: Int = 0) {
			self.score = score
		}
	}

	public enum Action: Equatable {
		case task
		case onCloseButtonTapped
		case delegate(Delegate)

		public enum Delegate {
			case close
		}
	}

	public init() {}

	@Dependency(\.gameCenter.localPlayer.submitScore) var submitScore

	public var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
			switch action {
			case .task:
				defer { state.didReportScore = true }
				return .fireAndForget { [score = state.score, didReport = state.didReportScore] in
					if !didReport {
						do {
							try await submitScore(score)
						} catch {}
					}
				}
			case .onCloseButtonTapped:
				return .send(.delegate(.close))
			case .delegate(.close):
				return .none
			}
		}
	}
}

public struct GameOverView: View {
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.adaptiveSize) var adaptiveSize
	@State var isSharePresented = false
	public let store: StoreOf<GameOver>

	public init(store: StoreOf<GameOver>) {
		self.store = store
	}

	public var body: some View {
		WithViewStore(self.store, observe: { $0 }) { viewStore in
			ScrollView(showsIndicators: false) {
				VStack(spacing: self.adaptiveSize.pad(24)) {
					HStack {
						Spacer()
						Button(action: { viewStore.send(.onCloseButtonTapped, animation: .default) }) {
							Image(systemName: "xmark")
						}
					}
					.adaptiveFont(.cormorantMedium, size: 24)
					.padding()
					Text("🌆 Final Score: \(viewStore.score)! 🌃")
						.adaptiveFont(.cormorantMedium, size: 30)
						.foregroundColor(.adaptiveBlack)
						.multilineTextAlignment(.center)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

				Spacer()

				VStack(spacing: .grid(8)) {
					Divider()

					Text("Enjoying\nthe game?")
						.adaptiveFont(.cormorantMedium, size: 30)
						.foregroundColor(.adaptiveBlack)
						.multilineTextAlignment(.center)

					Button(action: {
						self.isSharePresented.toggle()
					}) {
						Text("Share with a friend")
							.adaptiveFont(.cormorantMedium, size: 17)
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
			.task { await viewStore.send(.task).finish() }
			.foregroundColor(self.colorScheme == .dark ? .photoGuesserCream : .black)
			.background(
				(self.colorScheme == .dark ? .black : Color.photoGuesserCream)
					.ignoresSafeArea()
			)
			.sheet(isPresented: self.$isSharePresented) {
				ActivityView(activityItems: [URL(string: "https://apps.apple.com/app/photoguessr/id6447366892")!])
					.ignoresSafeArea()
			}
		}
	}
}

#if DEBUG
struct GameOverView_Previews: PreviewProvider {
	static var previews: some View {
		Preview {
			GameOverView(
				store: .init(
					initialState: .init(),
					reducer: GameOver()
				)
			)
		}
	}
}
#endif
