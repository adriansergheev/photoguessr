import SwiftUI
import ApiClientLive
import SharedModels
import Nuke
import NukeUI
import Sliders
import Styleguide
import ComposableArchitecture

@MainActor
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
							HStack {
								Text("\(viewStore.score)")
									.bold()
								Spacer()
//								Text("♾️")
//									.bold()
								Text("1/10")
									.bold()
							}
						}

						if let photo = viewStore.currentInGamePhoto,
							 let imageUrl = photo.imageUrl {
							ZStack {
								VStack(alignment: .leading) {
									Spacer()
									HStack(alignment: .bottom) {
										Text(photo.title)
											.bold()
											.foregroundColor(.white)
										Spacer()

										VStack(spacing: .grid(3)) {
											Button {
												viewStore.send(.submitTapped)
											} label: {
												Image(systemName: "hand.thumbsup.circle")
													.resizable()
													.frame(width: 48, height: 48)
													.foregroundColor(.white)
													.padding(.trailing, .grid(2))
											}
											.disabled(viewStore.guess == nil)
											.opacity(viewStore.guess == nil ? 0.5 : 1.0)

											Button {
												viewStore.send(.toggleSlider, animation: .easeIn)
											} label: {
												Image(systemName: viewStore.slider == nil ? "arrow.up.circle" : "arrow.down.circle")
													.resizable()
													.frame(width: 48, height: 48)
													.foregroundColor(.white)
													.padding(.trailing, .grid(2))
											}
										}

									}
									.padding(.bottom, .grid(4))
									.padding(.leading, .grid(2))

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
								.padding([.bottom], .grid(4))
								.zIndex(1)

								makeImage(url: imageUrl)
									.aspectRatio(contentMode: .fill)
									.frame(width: proxy.size.width - 32)
							}
							.edgesIgnoringSafeArea([.bottom])
						} else {
							Spacer()
							ProgressView()
							Spacer()
						}
					}
					.padding([.leading, .trailing], .grid(2))
					.alert(
						self.store.scope(state: \.alert),
						dismiss: .alertDismissed
					)
					.onAppear {
						viewStore.send(.startGame)
					}
				}
			}
		}
	}

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
				initialState: Game.State(),
				reducer: Game()
			)
		)
	}
}
#endif
