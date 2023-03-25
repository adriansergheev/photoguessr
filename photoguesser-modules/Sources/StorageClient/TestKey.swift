import Foundation
import Dependencies
import XCTestDynamicOverlay

extension StorageClient: TestDependencyKey {
	public static let previewValue = Self(
		load: { _ in Data() },
		save: { _, _ in }
	)
	public static let testValue = Self(
		load: XCTUnimplemented("\(Self.self).load"),
		save: XCTUnimplemented("\(Self.self).save")
	)
}
