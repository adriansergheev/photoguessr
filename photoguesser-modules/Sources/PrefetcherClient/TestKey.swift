import Foundation
import Dependencies

extension PrefetcherClient: TestDependencyKey {
	public static let testValue = Self(
		prefetchImages: { _ in },
		cancelPrefetching: { },
		clearCache: { }
	)
}
