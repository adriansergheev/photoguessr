import SwiftUI
import GameFeature

@main
struct PhotoGuesser: App {
	var body: some Scene {
		WindowGroup {
			GameView(
				store: .init(
					initialState: Game.State(),
					reducer: Game()._printChanges()
				)
			)
		}
	}
}
