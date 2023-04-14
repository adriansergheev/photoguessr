import SwiftUI
import Styleguide

struct ColorSchemePicker: View {
	@Environment(\.colorScheme) var envColorScheme
	@Binding var colorScheme: UserSettings.ColorScheme

	var body: some View {
		ZStack {
			HStack {
				if self.colorScheme != .system {
					Spacer()
						.frame(maxWidth: .infinity)
				}
				if self.colorScheme == .light {
					Spacer()
						.frame(maxWidth: .infinity)
				}
				Rectangle()
					.fill(Color.photoGuesserCream)
					.cornerRadius(12)
					.frame(maxWidth: .infinity)
					.padding(4)
				if self.colorScheme == .system {
					Spacer()
						.frame(maxWidth: .infinity)
				}
				if self.colorScheme != .light {
					Spacer()
						.frame(maxWidth: .infinity)
				}
			}

			HStack {
				ForEach([UserSettings.ColorScheme.system, .dark, .light], id: \.self) { colorScheme in
					Button(
						action: {
							withAnimation(.easeOut(duration: 0.2)) {
								self.colorScheme = colorScheme
							}
						}
					) {
						Text(colorScheme.title)
							.adaptiveFont(.cormorantMedium, size: 14)
							.foregroundColor(Color.white)
							.colorMultiply(
								self.titleColor(
									colorScheme: self.envColorScheme,
									isSelected: self.colorScheme == colorScheme
								)
							)
							.frame(maxWidth: .infinity)
					}
					.buttonStyle(PlainButtonStyle())
				}
				.padding()
			}
		}
		.background(
			Rectangle()
				.fill(self.envColorScheme == .light ? Color.black : .hex(0x222222))
		)
		.cornerRadius(12)
	}

	func titleColor(colorScheme: ColorScheme, isSelected: Bool) -> Color {
		switch colorScheme {
		case .light, .dark:
			return isSelected ? .black : .hex(0x7d7d7d)
		@unknown default:
			return isSelected ? .white : .black
		}
	}
}

extension UserSettings.ColorScheme {
	fileprivate var title: LocalizedStringKey {
		switch self {
		case .dark:
			return "Dark"
		case .light:
			return "Light"
		case .system:
			return "System"
		}
	}
}
