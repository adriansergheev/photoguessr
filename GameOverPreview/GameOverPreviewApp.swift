import SwiftUI
import GameOver
import Styleguide

@main
struct GameOverPreviewApp: App {

	init() {
		Styleguide.registerFonts()
	}

	var body: some Scene {
		WindowGroup {
			GameOverView(
				store: .init(
					initialState: .init(),
					reducer: GameOver()
				)
			)
		}
	}
}
