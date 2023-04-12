import Foundation
import StorageClient
import SharedModels

extension StorageClient {
	public func loadGame() throws -> GameLocation {
		try self.load(GameLocation.self, from: savedGameLocationFileName)
	}

	public func saveGame(_ gameLocation: GameLocation) throws {
		try self.save(gameLocation, to: savedGameLocationFileName)
	}
}

public let savedGameLocationFileName = "saved-game"
