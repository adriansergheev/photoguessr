import SwiftUI
import Styleguide
import XCTestDynamicOverlay
import ComposableArchitecture

public struct BottomMenu {
	public var buttons: [Button]
	public var footerButton: Button
	public var message: Text?
	public var title: Text

	public init(
		title: Text,
		message: Text? = nil,
		buttons: [Button],
		footerButton: Button
	) {
		self.buttons = buttons
		self.footerButton = footerButton
		self.message = message
		self.title = title
	}

	public struct Button: Identifiable {
		public let action: () -> Void
		public let icon: Image
		public let id: UUID
		public let title: Text

		public init(
			title: Text,
			icon: Image,
			action: @escaping () -> Void = unimplemented("BottomMenu.Button.action")
		) {
			self.action = action
			self.icon = icon
			self.id = UUID()
			self.title = title
		}

		fileprivate init(
			title: Text,
			icon: Image,
			id: UUID,
			action: @escaping () -> Void = unimplemented("BottomMenu.Button.action")
		) {
			self.action = action
			self.icon = icon
			self.id = id
			self.title = title
		}

		fileprivate func additionalAction(_ action: @escaping () -> Void) -> Self {
			.init(title: self.title, icon: self.icon, id: self.id) {
				action()
				self.action()
			}
		}
	}
}

extension View {
	public func bottomMenu(
		item: Binding<BottomMenu?>
	) -> some View {
		BottomMenuWrapper(content: self, item: item)
	}
}

private struct BottomMenuWrapper<Content: View>: View {
	@Environment(\.colorScheme) var colorScheme
	//	@Environment(\.deviceState) var deviceState

	let content: Content
	@Binding var item: BottomMenu?

	var body: some View {
		ZStack(alignment: .bottom) {
			self.content
				.zIndex(0)

			ZStack(alignment: .bottom) {
				if let menu = self.item {
					Rectangle()
						.fill(Color.black.opacity(0.4))
						.frame(maxWidth: .infinity, maxHeight: .infinity)
						.onTapGesture { self.item = nil }
						.zIndex(1)
						.transition(.opacity)

					VStack(spacing: 24) {
						Group {
							HStack {
								menu.title
									.font(.system(size: 18))
									.foregroundColor(colorScheme == .light ? .photoGuesserBlack : .photoGuesserCream)
								Spacer()
							}

							if let message = menu.message {
								message
									.font(.system(size: 24))
									.foregroundColor(colorScheme == .light ? .photoGuesserBlack : .photoGuesserCream)
							}
						}
						.foregroundColor(self.colorScheme == .light ? .white : .photoGuesserCream)

						HStack(spacing: 24) {
							ForEach(menu.buttons) { button in
								MenuButton(
									button:
										button
										.additionalAction { self.item = nil }
								)
							}
						}
						Button(
							action: {
								self.item = nil
								menu.footerButton.action()
							}
						) {
							HStack {
								menu.footerButton.title
									.font(.system(size: 18))
								Spacer()
								menu.footerButton.icon
							}
						}
						.buttonStyle(
							ActionButtonStyle(
								backgroundColor: .black,
								foregroundColor: .photoGuesserCream
							)
						)
					}
					.frame(maxWidth: .infinity)
					.padding(.grid(6))
					.padding(.bottom)
					.background(self.colorScheme == .light ? Color.photoGuesserCream : .hex(0x242424))
					.zIndex(2)
					.transition(.move(edge: .bottom))
				}
			}
			.ignoresSafeArea()
		}
	}
}

private struct MenuButton: View {
	let button: BottomMenu.Button
	@Environment(\.colorScheme) var colorScheme

	var body: some View {
		Button(action: self.button.action) {
			VStack(spacing: 16) {
				self.button.icon
					.foregroundColor(self.colorScheme == .light ? .photoGuesserCream : .photoGuesserBlack)

				self.button.title
					.foregroundColor(self.colorScheme == .light ? .photoGuesserCream : .photoGuesserBlack)
					.font(.system(size: 18))
			}
			.foregroundColor(self.colorScheme == .light ? .photoGuesserBlack : .photoGuesserCream)
			.frame(maxWidth: .infinity)
			.padding([.top, .bottom], 24)
			.background(self.colorScheme == .light ? Color.hex(0x242424) : .photoGuesserCream)
			.cornerRadius(12)
		}
		.buttonStyle(MenuButtonStyle())
	}
}

public struct MenuButtonStyle: ButtonStyle {
	public func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
			.scaleEffect(configuration.isPressed ? 0.95 : 1.0)
	}
}

#if DEBUG
import Styleguide

struct BottomMenu_Classic_Previews: PreviewProvider {
	struct TestView: View {
		@State var menu: BottomMenu? = Self.sampleMenu

		var body: some View {
			Button("Present") { withAnimation { self.toggle() } }
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.bottomMenu(item: self.$menu.animation())
		}

		func toggle() {
			self.menu = self.menu == nil ? Self.sampleMenu : nil
		}

		static let sampleMenu = BottomMenu(
			title: Text("Solo"),
			message: Text("Are you sure you want to exit the game?"),
			buttons: [
				.init(title: Text("Keep Playing"), icon: Image(systemName: "arrowtriangle.right"))
			],
			//			footerButton: nil
			footerButton: .init(title: Text("End Game"), icon: Image(systemName: "flag"))
		)
	}

	static var previews: some View {
		Preview {
			TestView()
		}
	}
}
#endif
