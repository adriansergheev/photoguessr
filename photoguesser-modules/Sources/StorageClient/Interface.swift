import Dependencies
import Foundation

struct StorageClient: Sendable {
	var load: @Sendable (URL) throws -> Data
	var save: @Sendable (Data, URL) throws -> Void
}

extension DependencyValues {
	var dataManager: StorageClient {
		get { self[StorageClient.self] }
		set { self[StorageClient.self] = newValue }
	}
}
