import Dependencies
import Foundation
import XCTestDynamicOverlay

extension StorageClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		delete: unimplemented("\(Self.self).deleteAsync"),
		load: unimplemented("\(Self.self).loadAsync"),
		save: unimplemented("\(Self.self).saveAsync")
	)
}

extension StorageClient {
	public static let noop = Self(
		delete: { _ in },
		load: { _ in throw CancellationError() },
		save: { _, _ in }
	)
}
