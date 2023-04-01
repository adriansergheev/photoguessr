import Nuke
import Dependencies
import Foundation

extension PrefetcherClient: DependencyKey {
	public static let liveValue: Self = {
		let imagePrefetcher = ImagePrefetcher()
		return Self(
			prefetchImages: { imagePrefetcher.startPrefetching(with: $0) },
			cancelPrefetching: { imagePrefetcher.stopPrefetching() },
			clearCache: { ImageCache.shared.removeAll() }
		)
	}()
}
