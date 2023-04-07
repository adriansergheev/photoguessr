import SwiftUI
import AppFeature
import ComposableArchitecture

final class AppDelegate: NSObject, UIApplicationDelegate {
	let store = Store(
		initialState: AppReducer.State(),
		reducer: AppReducer()
	)
	var viewStore: ViewStore<Void, AppReducer.Action> {
		ViewStore(self.store.stateless)
	}

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		self.viewStore.send(.appDelegate(.didFinishLaunching))
		return true
	}
}

@main
struct PhotoGuesser: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
	@Environment(\.scenePhase) private var scenePhase

	init() {}

	var body: some Scene {
		WindowGroup {
			AppView(store: self.appDelegate.store)
		}
		.onChange(of: self.scenePhase) {
			self.appDelegate.viewStore.send(.didChangeScenePhase($0))
		}
	}
}
