import UIKit
import Tagged
import SwiftUI

public typealias FontName = Tagged<Font, String>

extension FontName {
	public static let cormorantMedium: Self = "Cormorant-Medium"
	public static let cormorantBold: Self = "Cormorant-Bold"
}

extension Font {
	public static func custom(_ name: FontName, size: CGFloat) -> Self {
		.custom(name.rawValue, size: size)
	}
}

extension View {
	public func adaptiveFont(
		_ name: FontName,
		size: CGFloat,
		configure: @escaping (Font) -> Font = { $0 }
	) -> some View {
		self.modifier(AdaptiveFont(name: name.rawValue, size: size, configure: configure))
	}
}

private struct AdaptiveFont: ViewModifier {
	@Environment(\.adaptiveSize) var adaptiveSize

	let name: String
	let size: CGFloat
	let configure: (Font) -> Font

	func body(content: Content) -> some View {
		content.font(self.configure(.custom(self.name, size: self.size + self.adaptiveSize.padding)))
	}
}

@discardableResult
public func registerFonts() -> Bool {
	[
		UIFont.registerFont(bundle: .module, fontName: "Cormorant-Medium", fontExtension: "ttf"),
		UIFont.registerFont(bundle: .module, fontName: "Cormorant-Bold", fontExtension: "ttf")
	]
		.allSatisfy { $0 }
}

extension UIFont {
	static func registerFont(bundle: Bundle, fontName: String, fontExtension: String) -> Bool {
		guard let fontURL = bundle.url(forResource: fontName, withExtension: fontExtension) else {
			print("Couldn't find font \(fontName)")
			return false
		}
		guard let fontDataProvider = CGDataProvider(url: fontURL as CFURL) else {
			print("Couldn't load data from the font \(fontName)")
			return false
		}
		guard let font = CGFont(fontDataProvider) else {
			print("Couldn't create font from data")
			return false
		}

		var error: Unmanaged<CFError>?
		let success = CTFontManagerRegisterGraphicsFont(font, &error)
		guard success else {
			print(
		"""
		Error registering font: \(fontName). Maybe it was already registered.\
		\(error.map { " \($0.takeUnretainedValue().localizedDescription)" } ?? "")
		"""
			)
			return true
		}

		return true
	}
}

#if DEBUG
struct Font_Previews: PreviewProvider {
	static var previews: some View {
		registerFonts()

		return VStack(alignment: .leading, spacing: 12) {
			ForEach(
				[10, 12, 14, 16, 18, 20, 24, 32, 60].reversed(),
				id: \.self
			) { fontSize in
				Text("Whereas recognition of the inherent dignity")
					.adaptiveFont(.cormorantMedium, size: CGFloat(fontSize))
			}
		}
	}
}
#endif
