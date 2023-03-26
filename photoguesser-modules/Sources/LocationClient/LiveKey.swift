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
			authorizationStatus: locationManager.authorizationStatus,
			requestWhenInUseAuthorization: locationManager.requestWhenInUseAuthorization,
			requestLocation: locationManager.requestLocation,
			reverseGeocodeLocation: { location in
				do {
					return .success(try await CLGeocoder().reverseGeocodeLocation(location))
				} catch let error {
					return .failure(error)
				}
			},
			delegate: stream
		)
	}
}

extension CLGeocoder {
	func reverseGeocodeLocation(_ location: CLLocation) async throws -> [CLPlacemark] {
		return try await withCheckedThrowingContinuation { continuation in
			self.reverseGeocodeLocation(location) { placemarks, error in
				if let error = error {
					continuation.resume(throwing: error)
				} else if let placemarks = placemarks {
					continuation.resume(returning: placemarks)
				} else {
					struct GeocoderError: Error {}
					continuation.resume(
						throwing: GeocoderError()
					)
				}
			}
		}
	}
}
