import Dependencies
import XCTestDynamicOverlay

extension DependencyValues {
	public var applicationClient: UIApplicationClient {
		get { self[UIApplicationClient.self] }
		set { self[UIApplicationClient.self] = newValue }
	}
}

extension UIApplicationClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		open: unimplemented("\(Self.self).open", placeholder: false),
		openSettingsURLString: unimplemented("\(Self.self).openSettingsURLString"),
		setUserInterfaceStyle: unimplemented("\(Self.self).setUserInterfaceStyle")
	)
}

extension UIApplicationClient {
	public static let noop = Self(
		open: { _, _ in false },
		openSettingsURLString: { "settings://photoguessr" },
		setUserInterfaceStyle: { _ in }
	)
}
