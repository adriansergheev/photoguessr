import Dependencies
import Foundation

extension StorageClient: DependencyKey {
	public static let liveValue = Self(
		load: { url in try Data(contentsOf: url) },
		save: { data, url in try data.write(to: url) }
	)
}
