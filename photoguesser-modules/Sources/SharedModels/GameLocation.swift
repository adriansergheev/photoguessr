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
			.init(location: .init(lat: 59.32, long: 18.06), name: "Stockholm"),
			.init(location: .init(lat: 47.00, long: 28.90), name: "Chișinău"),
			.init(location: .init(lat: 50.45, long: 30.52), name: "Kiev"),
			.init(location: .init(lat: 35.68, long: 139.69), name: "Tokyo")
		]
	}
}
