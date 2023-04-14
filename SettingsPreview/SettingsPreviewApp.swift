import SwiftUI
import Styleguide
import SettingsFeature

@main
struct SettingsPreviewApp: App {

	init() {
		Styleguide.registerFonts()
	}

	var body: some Scene {
		WindowGroup {
			Settings(
				store: .init(
					initialState: .init(),
					reducer: SettingsFeature()
						._printChanges()
				)
			)
		}
	}
}
