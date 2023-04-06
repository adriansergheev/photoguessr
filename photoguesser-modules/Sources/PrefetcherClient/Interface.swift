import Foundation
import Dependencies

public struct PrefetcherClient: Sendable {
	public var prefetchImages: @Sendable ([URL]) async -> Void
	public var cancelPrefetching: @Sendable () async -> Void
	public var clearCache: @Sendable () async -> Void
}

extension DependencyValues {
	public var prefetcher: PrefetcherClient {
		get { self[PrefetcherClient.self] }
		set { self[PrefetcherClient.self] = newValue }
	}
}
