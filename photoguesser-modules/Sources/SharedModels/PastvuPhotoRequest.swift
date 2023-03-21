import Foundation

public struct PastvuPhotoRequest: Equatable, Encodable, Sendable {
	let geo: [Double]
	let limit: Int
	let except: Int?

	public init(geo: [Double], limit: Int, except: Int? = nil) {
		self.geo = geo
		self.limit = limit
		self.except = except
	}
}