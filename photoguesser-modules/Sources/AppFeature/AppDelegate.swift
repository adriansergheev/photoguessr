import Foundation
import Dependencies
import StorageClient
import SettingsFeature
import UIApplicationClient
import ComposableArchitecture

public struct AppDelegateReducer: ReducerProtocol {
	public typealias State = UserSettings

	@Dependency(\.storage) var storageClient
	@Dependency(\.applicationClient.setUserInterfaceStyle) var setUserInterfaceStyle

	public enum Action: Equatable {
		case didFinishLaunching
		case userSettingsLoaded(TaskResult<UserSettings>)
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .didFinishLaunching:
				return .task {
					await .userSettingsLoaded(
						TaskResult { try await self.storageClient.loadUserSettings() }
					)
				}
			case let .userSettingsLoaded(result):
				state = (try? result.value) ?? state
				return .fireAndForget { [state] in
					await self.setUserInterfaceStyle(state.colorScheme.userInterfaceStyle)
				}
			}
		}
	}
}
