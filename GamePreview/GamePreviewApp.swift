import GameFeature
import SwiftUI

@main
struct GamePreviewApp: App {
	var body: some Scene {
		WindowGroup {
			GameView(
				store: .init(
					initialState: .init(),
					reducer: Game()
				)
			)
		}
	}
}
