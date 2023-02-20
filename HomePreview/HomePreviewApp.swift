import HomeFeature
import SwiftUI

@main
struct HomePreviewApp: App {
	var body: some Scene {
		WindowGroup {
			HomeView(
				store: .init(initialState: .init(), reducer: Home())
			)
		}
	}
}
