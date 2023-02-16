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

	public var queryItems: [URLQueryItem]? {
		switch self {
		case let .giveNearestPhotos(request):
			let jsonData = try! jsonEncoder.encode(request)
			let jsonString = String(data: jsonData, encoding: .utf8)!

			return [
				.init(name: "method", value: "photo.giveNearestPhotos"),
				.init(name: "params", value: jsonString)
			]
		}
	}

	public var httpBody: Data? {
		nil
	}
}
