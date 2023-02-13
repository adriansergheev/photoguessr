import Foundation
import Dependencies
@_exported import ApiClient

/*
 https://pastvu.com/
 
 pic ex:
 https://pastvu.com/_p/d/t/t/m/ttmrs80811yfro4md7.jpeg
 
 query ex:
 https://pastvu.com/api2?method=photo.giveNearestPhotos&params={"geo":[37.82,-122.469322],"limit":100,"except":228481}
 
 */

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
