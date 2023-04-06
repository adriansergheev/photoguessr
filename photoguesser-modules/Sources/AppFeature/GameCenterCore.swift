import ComposableArchitecture

public struct GameCenterLogic: ReducerProtocol {
	@Dependency(\.gameCenter) var gameCenter

	public func reduce(
		into state: inout AppReducer.State,
		action: AppReducer.Action
	) -> Effect<AppReducer.Action> {
		switch action {
		case .appDelegate(.didFinishLaunching):
			return .run { _ in
				try await self.gameCenter.localPlayer.authenticate()
			}
		case .didChangeScenePhase:
			return .none
		case .home:
			return .none
		}
	}
}
