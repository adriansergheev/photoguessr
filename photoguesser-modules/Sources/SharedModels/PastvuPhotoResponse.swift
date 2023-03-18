import Foundation

public struct PastvuPhotoResponse: Codable, Equatable {
	public let result: Result
	public let rid: String

	public init(result: Result, rid: String) {
		self.result = result
		self.rid = rid
	}
}

public struct Result: Codable, Equatable {
	public let photos: [Photo]

	public init(photos: [Photo]) {
		self.photos = photos
	}
}

public struct Photo: Codable, Equatable {
	public let s, cid: Int
	public let file, title: String
	public let direction: String?
	public let geo: [Double]

	// TODO: move year tuple in a enum
	public let year: Int
	public let yearUpperBound: Int?

	public let ccount: Int?

	public init(
		s: Int,
		cid: Int,
		file: String,
		title: String,
		direction: String?,
		geo: [Double],
		year: Int,
		yearUpperBound: Int?,
		ccount: Int?
	) {
		self.s = s
		self.cid = cid
		self.file = file
		self.title = title
		self.direction = direction
		self.geo = geo
		self.year = year
		self.yearUpperBound = yearUpperBound
		self.ccount = ccount
	}

	enum CodingKeys: String, CodingKey {
		case s
		case cid
		case file
		case title
		case direction = "dir"
		case geo
		case year = "year"
		case yearUpperBound = "year2"
		case ccount
	}
}

extension Photo {
	public var imageUrl: URL? {
		let base = "https://pastvu.com/_p/d/"
		return URL(string: base.appending(self.file))
	}
}

extension Photo {
	public enum Year {
		case year(Int)
		case range(lowerBound: Int, upperBound: Int)
	}

	public var specificYear: Year {
		if let yearUpperBound {
			if yearUpperBound != self.year {
				return .range(lowerBound: self.year, upperBound: yearUpperBound)
			}
		}
		return .year(self.year)
	}
}
