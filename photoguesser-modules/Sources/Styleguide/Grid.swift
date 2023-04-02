import CoreGraphics

extension CGFloat {
	public static func grid(_ n: Int) -> Self { Self(n) * 4.0 }
}

import UIKit
// TODO: Replace with: https://stackoverflow.com/questions/75375870/uiscreen-main-is-deprecated-what-are-other-solutions-other-than-geometryreader
extension UIScreen {
	public static var height: CGFloat { UIScreen.main.bounds.height }
	public static var width: CGFloat { UIScreen.main.bounds.width }
}
