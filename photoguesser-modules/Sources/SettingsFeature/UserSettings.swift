import SwiftUI

public struct UserSettings: Codable, Equatable {
	public var colorScheme: ColorScheme

	public init(colorScheme: ColorScheme = .system) {
		self.colorScheme = colorScheme
	}

	public enum ColorScheme: String, CaseIterable, Codable {
		case dark
		case light
		case system

		public var userInterfaceStyle: UIUserInterfaceStyle {
			switch self {
			case .dark:
				return .dark
			case .light:
				return .light
			case .system:
				return .unspecified
			}
		}
	}
}
