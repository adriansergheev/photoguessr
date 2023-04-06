import Dependencies
import XCTestDynamicOverlay

extension GameCenterClient: TestDependencyKey {
	public static let testValue = Self(
		localPlayer: .unimplemented
	)
}

extension LocalPlayerClient {
	public static let unimplemented = Self(
		authenticate: XCTUnimplemented("\(Self.self).authenticate"),
		localPlayer: XCTUnimplemented("\(Self.self).localPlayer")
//		presentAuthenticationViewController: XCTUnimplemented(
//			"\(Self.self).presentAuthenticationViewController"
//		)
	)

}
