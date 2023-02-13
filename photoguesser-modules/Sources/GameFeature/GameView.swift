import SwiftUI
import ApiClientLive
import SharedModels
import ComposableArchitecture

struct GAlert: Identifiable {
	var id: String { content }
	let content: String
}

public struct GameView: View {
	
	@State private var alertData: GAlert?
	@State private var guess: Double = 1899
	@State private var score: Int = 0
	@State var nearestPhotos: NearestPhotosResponse?
	
	public init() { }
	
	public var body: some View {
		VStack {
			VStack(alignment: .trailing) {
				HStack {
					Text("Daily Challenge")
						.bold()
					Spacer()
					Text("Score: \(score)")
						.bold()
				}
			}
			Image(
				uiImage: UIImage(named: "demo", in: Bundle.module, with: nil)!
			)
			.resizable()
			.aspectRatio(contentMode: .fill)
			.foregroundColor(.accentColor)
			
			Spacer()
			Text("\(String(Int(self.guess)))")
			Slider(value: self.$guess, in: 1800...2000, step: 1)
				.tint(Color.black)
			Button {
				
				let range = 1900...1910
				let guess = Int(guess)
				//
				switch guess {
				case let guess where range.contains(guess):
					self.alertData = GAlert(content: "You nailed it!")
					self.score += 10
				case let guess where guess > 1910:
					self.alertData = GAlert(content: "Try lower!")
				case let guess where guess 	< 1910:
					self.alertData = GAlert(content: "Try higher!")
				default: break
				}
				
				
			} label: {
				Text("Submit")
					.tint(Color.black)
			}
		}
		.padding()
		.alert(item: $alertData) { data in
			Alert(
				title: Text("Points"),
				message: Text(data.content),
				dismissButton: .cancel()
			)
		}
		.task {
			do {
				let client = ApiClient.live()
				let nearestPhotos = try await client.giveNearestPhotos(.init())
				self.nearestPhotos = nearestPhotos
				print(nearestPhotos)
			} catch let error {
				print(error)
			}
		}
	}
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		GameView()
	}
}
#endif
