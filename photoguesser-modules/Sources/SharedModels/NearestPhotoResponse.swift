import Foundation

// MARK: - NearestPhotosResponse
public struct NearestPhotosResponse: Codable, Equatable {
	public let result: Result
	public let rid: String
	
	public init(result: Result, rid: String) {
		self.result = result
		self.rid = rid
	}
}

// MARK: - Result
public struct Result: Codable, Equatable {
	public let photos: [Photo]
	
	public init(photos: [Photo]) {
		self.photos = photos
	}
}

// MARK: - Photo
public struct Photo: Codable, Equatable {
	public let s, cid: Int
	public let file, title: String
	public let dir: String?
	public let geo: [Double]
	public let year: Int
	public let ccount: Int?
	
	init(
		s: Int,
		cid: Int,
		file: String,
		title: String,
		dir: String?,
		geo: [Double],
		year: Int,
		ccount: Int?
	) {
		self.s = s
		self.cid = cid
		self.file = file
		self.title = title
		self.dir = dir
		self.geo = geo
		self.year = year
		self.ccount = ccount
	}
}
