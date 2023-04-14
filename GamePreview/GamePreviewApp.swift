import SwiftUI
import GameFeature
import Styleguide

@main
struct GamePreviewApp: App {

	init() {
		Styleguide.registerFonts()
	}
	var body: some Scene {
		WindowGroup {
			GameView(
				store: .init(
					initialState: .init(
						gameLocation: .init(location: .init(lat: 55.67594, long: 12.56553), name: "Copenhagen")
					),
					reducer: Game()
				)
			)
		}
	}
}
