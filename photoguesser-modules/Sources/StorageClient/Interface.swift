import Foundation
import Dependencies

public struct StorageClient: Sendable {
	public var load: @Sendable (URL) throws -> Data
	public var save: @Sendable (Data, URL) throws -> Void
}

extension DependencyValues {
	public var storage: StorageClient {
		get { self[StorageClient.self] }
		set { self[StorageClient.self] = newValue }
	}
}
