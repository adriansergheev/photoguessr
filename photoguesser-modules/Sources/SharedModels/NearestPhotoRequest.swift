import Foundation

public struct NearestPhotoRequest: Equatable, Encodable, Sendable {
	let geo: [Double]
	let limit: Int
	let except: Int

	public init(geo: [Double], limit: Int, except: Int) {
		self.geo = geo
		self.limit = limit
		self.except = except
	}
}
