import GameKit
import UIKit
import Dependencies

extension DependencyValues {
	public var gameCenter: GameCenterClient {
		get { self[GameCenterClient.self] }
		set { self[GameCenterClient.self] = newValue }
	}
}

extension GameCenterClient: DependencyKey {
	public static let liveValue = Self(
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
			localPlayer: { .init(rawValue: localPlayer) }
			//			presentAuthenticationViewController: {
			//				await Self.viewController?.present()
			//				await AsyncStream<Void> { continuation in
			//					continuation.onTermination = { _ in
			//						Task {
			//							await Self.viewController?.dismiss()
			//							Self.viewController = nil
			//						}
			//					}
			//				}
			//				.first(where: { true })
			//			}
		)
	}
	private static var viewController: UIViewController?
}

extension UIViewController {
	//	public func present() {
	//		guard let scene = UIApplication.shared
	//			.connectedScenes
	//			.first(where: { $0 is UIWindowScene }) as? UIWindowScene else {
	//			return
	//		}
	//		scene.keyWindow?.rootViewController?.present(self, animated: true)
	//	}

	public func dismiss() {
		self.dismiss(animated: true, completion: nil)
	}
}
