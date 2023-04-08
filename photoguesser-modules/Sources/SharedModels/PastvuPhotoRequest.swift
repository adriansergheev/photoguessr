import Foundation

// https://docs.pastvu.com/en/dev/api
// photo.giveNearestPhotos
public struct PastvuPhotoRequest: Equatable, Encodable, Sendable {
	let geo: [Double]
	let distance: Int // distance in meters
	let year: Int // lower limit
	let type: String // photo / painting
	let limit: Int
	let except: Int?

	public init(
		geo: [Double],
		distance: Int = 10_000,
		year: Int = 1900,
		type: String = "photo",
		limit: Int = 30,
		except: Int? = nil
	) {
		self.geo = geo
		self.distance = distance
		self.year = year
		self.type = type
		self.limit = limit
		self.except = except
	}
}
