import SwiftUI
import GameOver

@main
struct GameOverPreviewApp: App {
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
