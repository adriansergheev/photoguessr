import Foundation
import Dependencies
@_exported import ApiClient

extension ApiClient: DependencyKey {
	public static var liveValue: ApiClient { Self.live() }
	
	public static func live() -> Self {
		Self(
			apiRequest: { apiEndpoint in
				return try await Self.apiRequest(apiEndpoint: apiEndpoint)
			}, giveNearestPhotos: { request in
				guard let request = Self.makeRequest(for: PastvuEndpoint.giveNearestPhotos(request)) else {
					throw URLError(.badURL)
				}
				let (data, _) = try await apiRequest(request)
				return try apiDecode(data: data, as: PastvuEndpoint.Response.self)
			}
		)
	}
}
