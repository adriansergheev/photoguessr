import SwiftUI
import Styleguide
import HomeFeature

@main
struct HomePreviewApp: App {

	init() {
		Styleguide.registerFonts()
	}

	var body: some Scene {
		WindowGroup {
			HomeView(
				store: .init(initialState: .init(), reducer: Home())
			)
		}
	}
}
