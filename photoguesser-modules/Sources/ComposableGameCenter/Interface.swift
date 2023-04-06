import Foundation
import GameKit

public struct GameCenterClient {
	//	public var gameCenterViewController: GameCenterViewControllerClient
	public var localPlayer: LocalPlayerClient
}

public struct LocalPlayerClient {
	public var authenticate: @Sendable () async throws -> Void
	public var localPlayer: @Sendable () -> LocalPlayer
//	public var presentAuthenticationViewController: @Sendable () async -> Void
}

// public struct GameCenterViewControllerClient {
//	public var present: @Sendable () async -> Void
//	public var dismiss: @Sendable () async -> Void
// }
