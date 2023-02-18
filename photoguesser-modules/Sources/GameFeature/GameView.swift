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
				GameNavView()
				GeometryReader { proxy in
					VStack {
						VStack(alignment: .trailing) {
							HStack(alignment: .center) {
								Text("\(viewStore.score)")
									.bold()
									.frame(width: 60)
								Spacer()
								if let guess = viewStore.guess {
									Text(verbatim: "\(guess)")
										.font(.system(size: 24))
										.bold()
								}
								Spacer()
								//								Text("♾️")
								//									.bold()
								Text("1/10")
									.frame(width: 60)
									.bold()
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
										HStack(alignment: .bottom) {
											Text(photo.title)
												.padding(.grid(2))
												.bold()
												.foregroundColor(Color.adaptiveBlack)
												.background(.ultraThinMaterial.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
											Spacer()
											Button {
												viewStore.send(.toggleSlider, animation: .easeIn)
											} label: {
												Image(systemName: viewStore.slider == nil ? "arrow.up.circle" : "arrow.down.circle")
													.resizable()
													.frame(width: 48, height: 48)
													.foregroundColor(.black)
													.background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
													.clipShape(Circle())
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
							ProgressView()
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
