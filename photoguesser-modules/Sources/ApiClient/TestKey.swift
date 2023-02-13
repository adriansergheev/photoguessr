import Foundation
import Dependencies

extension DependencyValues {
	public var apiClient: ApiClient {
		get { self[ApiClient.self] }
		set { self[ApiClient.self] = newValue }
	}
}

extension ApiClient: TestDependencyKey {
	public static let previewValue: ApiClient = Self.noop
	public static var testValue: ApiClient {
		Self(
			apiRequest: XCTUnimplemented("\(Self.self).apiRequest"),
			giveNearestPhotos: XCTUnimplemented("\(Self.self).giveNearestPhotos")
		)
	}
}

extension ApiClient {
	public static let noop = Self(
		apiRequest: { _ in try await Task.never() },
		giveNearestPhotos: { _ in try await Task.never()}
	)
}

