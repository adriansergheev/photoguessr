import SwiftUI
import SettingsFeature

@main
struct SettingsPreviewApp: App {
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
