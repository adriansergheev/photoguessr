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

		// https://forums.swift.org/t/asyncsequence-stream-version-of-passthroughsubject-or-currentvaluesubject/60395/7
		let stream = AsyncStream(bufferingPolicy: .bufferingOldest(0)) { continuation in
			let cancellable = subject.sink { signal in
				continuation.yield(signal)
			}
			continuation.onTermination = { _ in
				cancellable.cancel()
			}
		}

		return Self(
			authorizationStatus: { .authorizedWhenInUse },
			requestWhenInUseAuthorization: { },
			requestLocation: {
				subject.send(.didUpdateLocations([CLLocation()]))
			},
			reverseGeocodeLocation: { _ in .success([]) },
			delegate: stream
		)
	}
}
