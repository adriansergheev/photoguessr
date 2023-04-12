import StorageClient

extension StorageClient {
	public func loadUserSettings() async throws -> UserSettings {
		try self.load(UserSettings.self, from: userSettingsFileName)
	}

	public func save(userSettings: UserSettings) async throws {
		try self.save(userSettings, to: userSettingsFileName)
	}
}

public let userSettingsFileName = "user-settings"
