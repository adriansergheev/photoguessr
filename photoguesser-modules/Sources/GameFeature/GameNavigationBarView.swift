import SwiftUI
import Styleguide
import ComposableArchitecture

public struct GameNavigationBar: ReducerProtocol {
	public struct State: Equatable {
		var title: String
		init(title: String) {
			self.title = title
		}
	}

	public enum Action: Equatable {
		case onMenuButtonTapped
	}

	public init() {}
	public var body: some ReducerProtocol<State, Action> {
		Reduce { _, action in
			switch action {
			case .onMenuButtonTapped:
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
		WithViewStore(self.store, observe: { $0.title }) { viewStore in
			HStack(alignment: .center, spacing: .grid(2)) {
				TextStyle(
					text: viewStore.state,
					padding: .grid(1)
				)
				Spacer()
				Button(action: {
					ViewStore(self.store.stateless).send(.onMenuButtonTapped, animation: .default)
				}) {
					Image(systemName: "ellipsis")
						.padding()
						.rotationEffect(.degrees(90))
						.foregroundColor(self.colorScheme == .dark ? .black : .photoGuesserCream)
						.background(self.colorScheme == .dark ? Color.photoGuesserCream : .black)
						.clipShape(
							RoundedRectangle(cornerRadius: 13, style: .continuous)
								.inset(by: 2)
						)
				}
				.frame(maxHeight: .infinity)
				.background(colorScheme == .dark ? Color.photoGuesserGold.opacity(0.05) : .white.opacity(0.1))
				.cornerRadius(12)
			}
			.fixedSize(horizontal: false, vertical: true)
			.padding([.leading, .trailing])
			.padding([.top, .bottom], .grid(2))
			.background(
				colorScheme == .dark ? Color.black : Color.photoGuesserCream.opacity(0.9)
			)
		}
	}
}

#if DEBUG
struct GameNavView_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			GameNavigationBarView(
				store: .init(
					initialState: .init(title: "City"),
					reducer: GameNavigationBar()
				)
			)
			Spacer()
		}
	}
}
#endif
