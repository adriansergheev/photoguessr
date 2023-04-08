import Foundation

public struct GameLocation: Codable, Equatable {
	public typealias GamePhotos = PastvuPhotoResponse
	public let location: CanonicalLocation
	public let name: String

	public var gamePhotos: GamePhotos?

	public init(location: CanonicalLocation, name: String) {
		self.location = location
		self.name = name
	}
}

extension GameLocation: Identifiable {
	// TODO: revisit for uniqueness
	public var id: Double { 360 * round(location.lat) + round(location.long) }
}

extension GameLocation {
	public var imageUrls: [URL]? {
		if let gamePhotos {
			return gamePhotos.result.photos.compactMap { $0.imageUrl }
		} else {
			return nil
		}
	}
}

public struct CanonicalLocation: Codable, Equatable {
	public typealias Coordinate = Double

	public let lat: Coordinate
	public let long: Coordinate

	public init(lat: Coordinate, long: Coordinate) {
		self.lat = lat
		self.long = long
	}
}

extension GameLocation {
	public static var defaults: [GameLocation] {
		[
			.init(location: .init(lat: 37.77, long: -122.41), name: "San-Francisco"),
			.init(location: .init(lat: 41.90, long: 12.49), name: "Rome"),
			.init(location: .init(lat: 35.68, long: 139.69), name: "Tokyo"),
			.init(location: .init(lat: 44.43, long: 26.09), name: "Bucharest"),
			.init(location: .init(lat: 48.86, long: 2.34), name: "Paris"),
			.init(location: .init(lat: 40.73, long: -73.93), name: "New-York")
		]
	}
}
