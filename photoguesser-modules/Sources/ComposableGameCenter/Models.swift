import Foundation
import GameKit
import Tagged

@dynamicMemberLookup
public struct LocalPlayer: Equatable {
	public var isAuthenticated: Bool
	public var isMultiplayerGamingRestricted: Bool
	public var player: Player
	public let rawValue: GKLocalPlayer?

	public init(rawValue: GKLocalPlayer) {
		self.isAuthenticated = rawValue.isAuthenticated
		self.isMultiplayerGamingRestricted = rawValue.isMultiplayerGamingRestricted
		self.player = .init(rawValue: rawValue)
		self.rawValue = rawValue
	}

	public init(
		isAuthenticated: Bool,
		isMultiplayerGamingRestricted: Bool,
		player: Player
	) {
		self.isAuthenticated = isAuthenticated
		self.isMultiplayerGamingRestricted = isMultiplayerGamingRestricted
		self.player = player
		self.rawValue = nil
	}

	public subscript<Value>(dynamicMember keyPath: WritableKeyPath<Player, Value>) -> Value {
		get { self.player[keyPath: keyPath] }
		set { self.player[keyPath: keyPath] = newValue }
	}
}

public struct Player: Equatable {
	public typealias Id = Tagged<Player, String>

	public var alias: String
	public var displayName: String
	public var gamePlayerId: Id
	public let rawValue: GKPlayer?

	public init(rawValue: GKPlayer) {
		self.alias = rawValue.alias
		self.displayName = rawValue.displayName
		self.gamePlayerId = .init(rawValue: rawValue.gamePlayerID)
		self.rawValue = rawValue
	}

	public init(
		alias: String,
		displayName: String,
		gamePlayerId: Id
	) {
		self.alias = alias
		self.displayName = displayName
		self.gamePlayerId = gamePlayerId
		self.rawValue = nil
	}

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.displayName == rhs.displayName
	}
}
