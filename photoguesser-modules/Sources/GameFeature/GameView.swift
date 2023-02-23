import SwiftUI
import ApiClientLive
import SharedModels
import Nuke
import NukeUI
import Sliders
import Styleguide
import GameNotification
import ComposableArchitecture

public struct GameView: View {
	public let store: StoreOf<Game>

	private let pipeline = ImagePipeline {
		$0.dataLoader = {
			let config = URLSessionConfiguration.default
			config.urlCache = nil
			return Nuke.DataLoader(configuration: config)
		}()
	}

	public init(store: StoreOf<Game>) {
		self.store = store
	}

	public var body: some View {
		WithViewStore(self.store) { viewStore in
			VStack {
				GameNavigationBarView(
					store: self.store.scope(
						state: \.navigationBar,
						action: Game.Action.gameNavigationBar
					)
				)
				GeometryReader { proxy in
					VStack {
						VStack(alignment: .trailing) {
							HStack(alignment: .center) {
								Text("\(viewStore.score)")
									.bold()
									.padding(.leading, .grid(4))
								Spacer()
								if let guess = viewStore.guess {
									Text(verbatim: "\(guess)")
										.font(.system(size: 24))
										.bold()
								}
								Spacer()

								switch viewStore.mode {
								case .unlimited:
									Text("♾️")
										.foregroundColor(.adaptiveBlack)
										.bold()
										.padding(.trailing, .grid(4))
								case let .limited(max: limit, current: current):
									Text("\(current)/\(limit)")
										.bold()
										.padding(.trailing, .grid(4))
								}
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

								makeImage(url: imageUrl)
									.aspectRatio(contentMode: .fill)
									.frame(width: proxy.size.width - 32)
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
		}
	}

	@MainActor
	func makeImage(url: URL) -> some View {
		LazyImage(url: url)
			.animation(.default)
			.pipeline(pipeline)
	}
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
