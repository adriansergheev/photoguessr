import Foundation
import ApiClient
import SharedModels

public enum PastvuEndpoint {
	case giveNearestPhotos(NearestPhotoRequest)
}

extension PastvuEndpoint: APIEndpoint {
	
	public typealias Response = NearestPhotosResponse
	
	public var httpMethod: HTTPMethod {
		.get
	}
	
	public var path: String {
		"/api2/"
	}
	
	// Stockholm
	public var queryItems: [URLQueryItem]? {
		let mockParams = """
{"geo":[59.32938,18.06871],"limit":100,"except":228481}
"""
		return [
			.init(name: "method", value: "photo.giveNearestPhotos"),
			.init(name: "params", value: mockParams)
		]
	}
	
	public var httpBody: Data? {
		nil
	}
}

