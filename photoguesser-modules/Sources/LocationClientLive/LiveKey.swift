import Dependencies
import LocationClient
import Combine
import CoreLocation

extension LocationClient: DependencyKey {
	public static var liveValue: LocationClient {
		class Delegate: NSObject, CLLocationManagerDelegate {
			let subject: PassthroughSubject<DelegateEvent, Never>

			init(subject: PassthroughSubject<DelegateEvent, Never>) {
				self.subject = subject
			}

			func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
				self.subject.send(.didChangeAuthorization(status))
			}

			func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
				self.subject.send(.didUpdateLocations(locations))
			}

			func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
				self.subject.send(.didFailWithError(error))
			}
		}

		let locationManager = CLLocationManager()
		let subject = PassthroughSubject<DelegateEvent, Never>()
		let delegate: Delegate? = Delegate(subject: subject)
		locationManager.delegate = delegate
		// https://forums.swift.org/t/asyncsequence-stream-version-of-passthroughsubject-or-currentvaluesubject/60395/7
		let stream = AsyncStream(bufferingPolicy: .bufferingOldest(0)) { continuation in
			let cancellable = subject.sink { signal in
				continuation.yield(signal)
			}
			continuation.onTermination = { _ in
				_ = delegate
				cancellable.cancel()
			}
		}

		return Self(
			authorizationStatus: CLLocationManager.authorizationStatus,
			requestWhenInUseAuthorization: locationManager.requestWhenInUseAuthorization,
			requestLocation: locationManager.requestLocation,
			delegate: stream
		)
	}
}
