import Dependencies
import Foundation

extension DependencyValues {
	public var userDefaults: UserDefaultsClient {
		get { self[UserDefaultsClient.self] }
		set { self[UserDefaultsClient.self] = newValue }
	}
}

public struct UserDefaultsClient {
	public var boolForKey: @Sendable (String) -> Bool
	public var dataForKey: @Sendable (String) -> Data?
	public var doubleForKey: @Sendable (String) -> Double
	public var integerForKey: @Sendable (String) -> Int
	public var remove: @Sendable (String) async -> Void
	public var setBool: @Sendable (Bool, String) async -> Void
	public var setData: @Sendable (Data?, String) async -> Void
	public var setDouble: @Sendable (Double, String) async -> Void
	public var setInteger: @Sendable (Int, String) async -> Void

	public var isNotWillingToShareLocation: Bool {
		self.boolForKey(isSharingLocationKey)
	}
	public func setNotSharingLocationPreference(_ bool: Bool) async {
		await self.setBool(bool, isSharingLocationKey)
	}
}
let isSharingLocationKey: String = "isSharingLocationKey"
