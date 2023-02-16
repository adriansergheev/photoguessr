import SwiftUI
import ApiClientLive
import SharedModels
import Nuke
import NukeUI
import Sliders
import ComposableArchitecture

@MainActor
public struct GameView: View {

	@State private var translation: CGSize = .zero

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
								Text("♾️")
									.bold()
							}
						}

						if let photo = viewStore.currentInGamePhoto,
							 let imageUrl = photo.imageUrl {
							ZStack {
								VStack(alignment: .leading) {
									Spacer()
									HStack {
										Text(photo.title)
											.bold()
											.foregroundColor(.white)
										Spacer()
									}
								}
								.padding([.bottom], 16)
								.zIndex(1)
								makeImage(url: imageUrl)
									.aspectRatio(contentMode: .fill)
									.frame(width: proxy.size.width - 32)
							}
							.offset(x: self.translation.width, y: 0)
							.rotationEffect(
								.degrees(Double(self.translation.width / proxy.size.width) * 25),
								anchor: .bottom
							)
							.gesture(
								DragGesture()
									.onChanged { value in
										if viewStore.guess != nil {
											self.translation = value.translation
										}
									}
									.onEnded { _ in
										withAnimation(.easeInOut) {
											if translation.width > 150 {
												self.translation = .zero
												viewStore.send(.submitTapped)
											} else if translation.width < -150 {
												//
												self.translation = .zero
											} else {
												self.translation = .zero
											}
										}
									}
							)
						} else {
							Spacer()
							ProgressView()
						}

						Spacer()

						if viewStore.showSubmitGuide {
							Text("Swipe picture to submit")
						} else if let guess = viewStore.guess {
							Text("\(String(guess))")
						} else {
							Text("Slide to play")
						}

						VStack {
							ValueSlider(
								value: viewStore.binding(get: \.sliderValue, send: Game.Action.sliderValueChanged),
								in: viewStore.sliderRange,
								step: 1
							)
							.valueSliderStyle(
								HorizontalValueSliderStyle(
									track: Color.black
										.frame(height: 6).cornerRadius(3),
									thumbSize: CGSize(width: 48, height: 16),
									options: .interactiveTrack
								)
							)
						}
						.frame(height: 36)
					}
					.padding([.leading, .trailing], 8)
					.padding([.bottom], 16)
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
