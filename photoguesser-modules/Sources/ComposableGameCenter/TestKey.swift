import Dependencies
import XCTestDynamicOverlay

extension GameCenterClient: TestDependencyKey {
	public static let testValue = Self(
		gameCenterViewController: .unimplemented,
		localPlayer: .unimplemented
	)
}

extension LocalPlayerClient {
	public static let unimplemented = Self(
		authenticate: XCTUnimplemented("\(Self.self).authenticate"),
		localPlayer: XCTUnimplemented("\(Self.self).localPlayer"),
		submitScore: XCTUnimplemented("\(Self.self).submitScore")
	)
}

extension GameCenterViewControllerClient {
	public static let unimplemented = Self(
		present: XCTUnimplemented("\(Self.self).present"),
		dismiss: XCTUnimplemented("\(Self.self).dismiss")
	)
}
