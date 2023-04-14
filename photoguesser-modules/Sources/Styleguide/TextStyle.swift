import SwiftUI

public struct TextStyle: View {
	@Environment(\.colorScheme) var colorScheme

	var text: String
	var padding: CGFloat

	public init(text: String, padding: CGFloat = .grid(2)) {
		self.text = text
		self.padding = padding
	}

	public var body: some View {
		Text(text)
			.adaptiveFont(.cormorantBold, size: 17)
			.padding(self.padding)
			.padding([.leading, .trailing], .grid(2))
			.foregroundColor(self.colorScheme == .dark ? .black : .photoGuesserCream)
			.background(self.colorScheme == .dark ? Color.photoGuesserCream : .black)
			.clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous).inset(by: 2))
	}
}
