import Foundation
import Combine
import CoreLocation
import Dependencies

extension DependencyValues {
	public var locationClient: LocationClient {
		get { self[LocationClient.self] }
		set { self[LocationClient.self] = newValue }
	}
}

extension LocationClient: TestDependencyKey {
	public static var testValue: LocationClient {
		let subject = PassthroughSubject<DelegateEvent, Never>()

		return Self(
			authorizationStatus: { .authorizedWhenInUse },
			requestWhenInUseAuthorization: { },
			requestLocation: {
				subject.send(.didUpdateLocations([CLLocation()]))
			},
			delegate: subject.eraseToAnyPublisher()
		)
	}
}
