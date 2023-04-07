import GameKit
import UIKit
import Dependencies

extension DependencyValues {
	public var gameCenter: GameCenterClient {
		get { self[GameCenterClient.self] }
		set { self[GameCenterClient.self] = newValue }
	}
}

let leaderboardId = "photoguessr_max_10"

extension GameCenterClient: DependencyKey {
	public static let liveValue = Self(
		gameCenterViewController: .live,
		localPlayer: .live
	)
}

extension LocalPlayerClient {
	public static var live: Self {
		var localPlayer: GKLocalPlayer { .local }

		return Self(
			authenticate: {
				_ = try await AsyncThrowingStream<Void, Error> { continuation in
					localPlayer.authenticateHandler = { viewController, error in
						if let error = error {
							continuation.finish(throwing: error)
							return
						}
						continuation.finish()
						if viewController != nil {
							Self.viewController = viewController
						}
					}
					continuation.onTermination = { _ in
						Task {
							await Self.viewController?.dismiss()
							Self.viewController = nil
						}
					}
				}
				.first(where: { true })
			},
			localPlayer: { .init(rawValue: localPlayer) },
			submitScore: { score in
				let gkLeaderboardScore = GKLeaderboardScore()
				gkLeaderboardScore.leaderboardID = leaderboardId
				gkLeaderboardScore.value = score
				gkLeaderboardScore.player = localPlayer
				try await GKScore.report(
					[gkLeaderboardScore],
					withEligibleChallenges: []
				)
			}
		)
	}
	private static var viewController: UIViewController?
}

extension GameCenterViewControllerClient {
	public static var live: Self {
		actor Presenter {
			var viewController: GKGameCenterViewController?

			func present() async {
				final class Delegate: NSObject, GKGameCenterControllerDelegate {
					let continuation: AsyncStream<Void>.Continuation

					init(continuation: AsyncStream<Void>.Continuation) {
						self.continuation = continuation
					}

					func gameCenterViewControllerDidFinish(
						_ gameCenterViewController: GKGameCenterViewController
					) {
						self.continuation.yield()
						self.continuation.finish()
					}
				}

				await self.dismiss()
				let viewController = await GKGameCenterViewController(
					leaderboardID: leaderboardId,
					playerScope: .global,
					timeScope: .allTime
				)
				self.viewController = viewController
				_ = await AsyncStream<Void> { continuation in
					Task {
						await MainActor.run {
							let delegate = Delegate(continuation: continuation)
							continuation.onTermination = { _ in
								_ = delegate
							}
							viewController.gameCenterDelegate = delegate
							viewController.present()
						}
					}
				}
				.first(where: { _ in true })
			}

			func dismiss() async {
				guard let viewController = self.viewController else { return }
				await MainActor.run {
					viewController.dismiss()
				}
				self.viewController = nil
			}
		}

		let presenter = Presenter()

		return Self(
			present: { await presenter.present() },
			dismiss: { await presenter.dismiss() }
		)
	}
	private static var viewController: GKGameCenterViewController?
}

extension UIViewController {
	public func present() {
		guard let scene = UIApplication.shared
			.connectedScenes
			.first(where: { $0 is UIWindowScene }) as? UIWindowScene else {
			return
		}
		scene.keyWindow?.rootViewController?.present(self, animated: true)
	}

	public func dismiss() {
		self.dismiss(animated: true, completion: nil)
	}
}
