import SwiftUI
import ApiClientLive
import SharedModels
import Nuke
import NukeUI
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
				VStack(alignment: .trailing) {
					HStack {
						Text("Daily Challenge")
							.bold()
						Spacer()
						Text("Score: \(viewStore.score)")
							.bold()
					}
				}

				if let currentPhotoFile = viewStore.currentGamePhoto?.file {
					let baseURL = "https://pastvu.com/_p/d/"
					makeImage(url: URL(string: baseURL.appending(currentPhotoFile))!)
						.aspectRatio(contentMode: .fill)
				} else {
					ProgressView()
				}

				
				Spacer()
//				if let guess = viewStore.guess {
//
//				}
				Text("\(String(Int(viewStore.sliderValue)))")
				Slider(value: viewStore.binding(get: \.sliderValue, send: Game.Action.sliderValueChanged), in: viewStore.range, step: 1)
					.tint(Color.black)
				Button {
					viewStore.send(.submitTapped)
				} label: {
					Text("Submit")
						.tint(Color.black)
				}
			}
			.padding()
			.alert(
				self.store.scope(state: \.alert),
				dismiss: .alertDismissed
			)
			.onAppear { viewStore.send(.startGame) }
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
				reducer: Game()._printChanges()
			)
		)
	}
}
#endif
