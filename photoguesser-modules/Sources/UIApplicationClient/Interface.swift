import UIKit

public struct UIApplicationClient {
	public var open: @Sendable (URL, [UIApplication.OpenExternalURLOptionsKey: Any]) async -> Bool
	public var openSettingsURLString: @Sendable () async -> String
	public var setUserInterfaceStyle: @Sendable (UIUserInterfaceStyle) async -> Void
}
