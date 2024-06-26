import Foundation
import Combine
import CoreLocation

public struct LocationClient {
	public var authorizationStatus: CLAuthorizationStatus
	public var requestWhenInUseAuthorization: () -> Void
	public var requestLocation: () -> Void
	public var reverseGeocodeLocation: (CLLocation) async -> Result<[CLPlacemark], Error>
	public var delegate: AsyncStream<DelegateEvent>

	public init(
		authorizationStatus: CLAuthorizationStatus,
		requestWhenInUseAuthorization: @escaping () -> Void,
		requestLocation: @escaping () -> Void,
		reverseGeocodeLocation: @escaping (CLLocation) async -> Result<[CLPlacemark], Error>,
		delegate: AsyncStream<DelegateEvent>
	) {
		self.authorizationStatus = authorizationStatus
		self.requestWhenInUseAuthorization = requestWhenInUseAuthorization
		self.requestLocation = requestLocation
		self.reverseGeocodeLocation = reverseGeocodeLocation
		self.delegate = delegate
	}

	public enum DelegateEvent {
		case didChangeAuthorization(CLAuthorizationStatus)
		case didUpdateLocations([CLLocation])
		case didFailWithError(Error)
	}
}
