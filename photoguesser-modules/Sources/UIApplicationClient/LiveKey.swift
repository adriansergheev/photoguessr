import Dependencies
import UIKit

extension UIApplicationClient: DependencyKey {
	public static let liveValue = Self(
		open: { @MainActor in await UIApplication.shared.open($0, options: $1) },
		openSettingsURLString: { await UIApplication.openSettingsURLString },
		setUserInterfaceStyle: { userInterfaceStyle in
			await MainActor.run {
				guard
					let scene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene })
						as? UIWindowScene
				else { return }
				scene.keyWindow?.overrideUserInterfaceStyle = userInterfaceStyle
			}
		}
	)
}
