import SwiftUI
import HomeFeature

@main
struct PhotoGuesser: App {
	var body: some Scene {
		WindowGroup {
			HomeView(
				store: .init(
					initialState: .init(),
					reducer: Home()._printChanges()
				)
			)
		}
	}
}
