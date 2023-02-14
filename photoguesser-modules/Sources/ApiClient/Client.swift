import Foundation
import XCTestDynamicOverlay
import SharedModels

public enum HTTPMethod: String {
	case get = "GET"
}

public protocol APIEndpoint {
	associatedtype Response: Decodable
	var httpMethod: HTTPMethod { get }
	var path: String { get }
	var queryItems: [URLQueryItem]? { get }
	var httpBody: Data? { get }
}

public struct ApiClient {
	public var apiRequest: (any APIEndpoint) async throws -> (data: Data, response: URLResponse)
	public var giveNearestPhotos: @Sendable (NearestPhotoRequest) async throws -> NearestPhotosResponse
	
	public init(
		apiRequest: @escaping (any APIEndpoint) async throws -> (data: Data, response: URLResponse),
		giveNearestPhotos: @escaping @Sendable (NearestPhotoRequest) async throws -> NearestPhotosResponse
	) {
		self.apiRequest = apiRequest
		self.giveNearestPhotos = giveNearestPhotos
	}
	
	public func apiRequest<T: Decodable>(
		_ apiEndpoint: any APIEndpoint,
		as: T.Type
	) async throws -> T {
		do {
			let data = try await apiRequest(apiEndpoint).data
			return try Self.apiDecode(data: data, as: T.self)
		}
	}
	
	public static func apiDecode<T: Decodable>(data: Data, as: T.Type) throws -> T {
		do {
			return try jsonDecoder.decode(T.self, from: data)
		}
	}
}

let jsonDecoder = JSONDecoder()

extension ApiClient {
	public static func apiRequest(
		apiEndpoint: any APIEndpoint
	) async throws -> (data: Data, response: URLResponse) {
		guard let request = makeRequest(for: apiEndpoint) else {
			throw URLError(.badURL)
		}
		return try await apiRequest(request)
	}
	
	
	public static func apiRequest(
		_ request: URLRequest
	) async throws -> (data: Data, response: URLResponse) {
		let (data, response) = try await URLSession.shared.data(for: request)
#if DEBUG
		print(
 """
 Request: \(request.url?.absoluteString ?? "")
 Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)
 Response: \(String(decoding: data, as: UTF8.self))
 """
		)
#endif
		return (data, response)
	}
	
	public static func makeRequest(
		for apiEndpoint: any APIEndpoint
	) -> URLRequest? {
		guard var request = request(for: apiEndpoint) else { return nil }
		addHeaders(to: &request)
		return request
	}
	
	private static func request(for apiEndpoint: any APIEndpoint) -> URLRequest? {
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = "pastvu.com"
		urlComponents.path = apiEndpoint.path
		urlComponents.queryItems = apiEndpoint.queryItems
		
		guard let url = urlComponents.url else {
#if DEBUG
			print(
 """
 URL Components is malformed. Check \(String(describing: urlComponents.scheme)), \(urlComponents.path)
 """
			)
#endif
			return nil
		}
		var request = URLRequest(url: url)
		request.httpMethod = apiEndpoint.httpMethod.rawValue
		request.httpBody = apiEndpoint.httpBody
		return request
	}
	
	private static func addHeaders(to request: inout URLRequest) {
		//
	}
}

#if DEBUG
extension ApiClient {
	public static func mock() -> Self {
		Self(
			apiRequest: XCTUnimplemented("\(Self.self).apiRequest"),
			giveNearestPhotos: { _ in
					.init(
						result: .init(
							photos: [
								Photo(
									s: 5,
									cid: 449470,
									file: "7/b/i/7bi9g0kfwouz0oho3b.jpeg",
									title: "Golden Gate Bridge construction",
									direction: "s",
									geo: [
										37.825334,
										-122.479094
									],
									year: 1935,
									yearUpperBound: nil,
									ccount: nil
								)
							]
						), rid: "cl1z1mcnjt"
					)
			}
		)
	}
}
#endif
