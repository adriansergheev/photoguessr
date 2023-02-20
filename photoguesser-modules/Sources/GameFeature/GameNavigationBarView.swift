import SwiftUI
import ComposableArchitecture

public struct GameNavigationBar: ReducerProtocol {
	public struct State: Equatable {}

	public enum Action: Equatable {
		case onSettingsTap
	}

	public init() {}
	public var body: some ReducerProtocol<State, Action> {
		Reduce { _, action in
			switch action {
			case .onSettingsTap:
				return .none
			}
		}
	}
}

struct GameNavigationBarView: View {
	let store: StoreOf<GameNavigationBar>
	@Environment(\.colorScheme) var colorScheme

	init(store: StoreOf<GameNavigationBar>) {
		self.store = store
	}

	var body: some View {
		WithViewStore(self.store) { viewStore in
			HStack(alignment: .center, spacing: .grid(2)) {
				Text("PhotoGuesser")
					.bold()
				Spacer()
				Button(action: {
					viewStore.send(.onSettingsTap)
				}) {
					Image(systemName: "ellipsis")
						.foregroundColor(.adaptiveBlack)
						.padding()
						.rotationEffect(.degrees(90))
				}
				.frame(maxHeight: .infinity)
				.background(colorScheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
				.cornerRadius(12)
			}
			.fixedSize(horizontal: false, vertical: true)
			.padding([.leading, .trailing])
			.padding([.top, .bottom], .grid(2))
		}
	}
}

#if DEBUG
struct GameNavView_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			GameNavigationBarView(
				store: .init(
					initialState: .init(),
					reducer: GameNavigationBar()
				)
			)
			Spacer()
		}
	}
}
#endif
