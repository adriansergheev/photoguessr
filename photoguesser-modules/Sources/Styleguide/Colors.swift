import SwiftUI

extension Color {
	public static let adaptiveWhite = Self {
		$0.userInterfaceStyle == .dark ? .photoGuesserBlack : .white
	}
	public static let adaptiveBlack = Self {
		$0.userInterfaceStyle == .dark ? .white : .photoGuesserBlack
	}
	public static let photoGuesserBlack = hex(0x121212)
	public static let photoGuesserBrown = hex(0x8B6C42)
	public static let photoGuesserCream = hex(0xFFFDD0)
	public static let photoGuesserGold = hex(0xFFD700)
}
extension Color {
	public static func hex(_ hex: UInt) -> Self {
		Self(
			red: Double((hex & 0xff0000) >> 16) / 255,
			green: Double((hex & 0x00ff00) >> 8) / 255,
			blue: Double(hex & 0x0000ff) / 255,
			opacity: 1
		)
	}
}

extension Color {
	public init(dynamicProvider: @escaping (UITraitCollection) -> Color) {
		self = Self(UIColor { UIColor(dynamicProvider($0)) })
	}
}
