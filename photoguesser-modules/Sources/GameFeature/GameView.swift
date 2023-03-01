import Nuke
import NukeUI
import SwiftUI
import Sliders
import GameOver
import Styleguide
import SharedModels
import ApiClientLive
import GameNotification
import ComposableArchitecture

public struct GameView: View {
	public let store: StoreOf<Game>
	@Environment(\.colorScheme) var colorScheme
	@ObservedObject public var viewStore: ViewStore<Game.State, Game.Action>

	public init(store: StoreOf<Game>) {
		self.store = store
		self.viewStore = ViewStore(self.store)
	}

	public var body: some View {
		ZStack {
			VStack {
				GameNavigationBarView(
					store: self.store.scope(
						state: \.navigationBar,
						action: Game.Action.gameNavigationBar
					)
				)
				GeometryReader { proxy in
					VStack {
						HStack {
							Text("\(viewStore.score)")
								.foregroundColor(.adaptiveBlack)
								.bold()
								.frame(width: 40)
								.padding(.leading, .grid(4))

							Spacer()
							Text(verbatim: "\(viewStore.guess ?? 0)")
								.foregroundColor(.adaptiveBlack)
								.font(.system(size: 24))
								.bold()
								.opacity(viewStore.guess != nil ? 1.0 : 0.0)
								.transaction { $0.animation = nil }
							Spacer()

							switch viewStore.mode {
							case .unlimited:
								Text("♾️")
									.bold()
									.frame(width: 40)
									.padding(.trailing, .grid(4))
							case let .limited(max: limit, current: current):
								Text("\(current)/\(limit)")
									.bold()
									.foregroundColor(.adaptiveBlack)
									.frame(width: 40)
									.padding(.trailing, .grid(4))
							}
						}

						if let photo = viewStore.currentInGamePhoto,
							 let imageUrl = photo.imageUrl {
							ZStack {
								VStack {
									IfLetStore(
										self.store.scope(
											state: \.gameNotification,
											action: Game.Action.gameNotification
										),
										then: { store in
											GameNotificationView(store: store)
												.padding(.grid(2))
										}
									)
									Spacer()
								}
								.zIndex(1)

								VStack(alignment: .leading) {
									Spacer()
									VStack(spacing: .grid(2)) {
										HStack(alignment: .center) {
											Text(photo.title)
												.padding(.grid(2))
												.bold()
												.foregroundColor(Color.adaptiveBlack)
												.background(.ultraThinMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
												.onTapGesture {
													viewStore.send(.toggleSlider, animation: .easeIn)
												}
											Spacer()
											Button {
												viewStore.send(.toggleSlider, animation: .easeIn)
											} label: {
												Image(systemName: "chevron.up")
													.rotationEffect(.degrees(viewStore.slider != nil ? 180 : 0))
													.foregroundColor(.adaptiveBlack)
													.padding(.grid(2))
													.background(.ultraThinMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 36, style: .continuous))
													.padding(.grid(2))
													.padding(.trailing, .grid(2))
											}
											.transaction { $0.animation = nil }
										}
										.padding(.leading, .grid(3))
										.padding(.bottom, viewStore.slider == nil ? .grid(16) : 0)
									}
									IfLetStore(
										self.store.scope(
											state: \.slider,
											action: Game.Action.slider
										),
										then: { store in
											CustomSliderView(store: store)
										}
									)
								}
								.zIndex(1)

								LazyImage(url: imageUrl, transaction: .init(animation: .default)) {
									$0.image
										.aspectRatio(contentMode: .fill)
										.frame(width: proxy.size.width - 32)
								}

							}
							.edgesIgnoringSafeArea(.bottom)
						} else {
							Spacer()
							if viewStore.isInEmptyState {
								Text("Could not find any pics for this location ;(")
									.foregroundColor(.adaptiveBlack)
							} else {
								ProgressView()
							}
							Spacer()
						}

					}
					.onAppear {
						viewStore.send(.startGame)
					}
				}
			}
			IfLetStore(
				self.store.scope(state: \.gameOver, action: Game.Action.gameOver),
				then: GameOverView.init(store:)
			)
			.background(Color.adaptiveWhite.ignoresSafeArea())
			.transition(
				.asymmetric(
					insertion: AnyTransition.opacity.animation(.linear(duration: 1)),
					removal: .game
				)
			)
			.zIndex(1)
		}
		.background(colorScheme == .dark ? .black : .photoGuesserCream)
	}
}
extension AnyTransition {
	public static let game = move(edge: .bottom)
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		GameView(
			store: .init(
				initialState: Game.State(score: 0, gameNotification: .init(text: "You nailed it! \(50) points!")),
				reducer: Game()
			)
		)
	}
}
#endif
