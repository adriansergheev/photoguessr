import SwiftUI
import Foundation
import Styleguide
import ComposableArchitecture

public struct SettingsFeature: Reducer {
	public struct State: Equatable {
		public init() {

		}
	}

	public enum Action: Equatable {
		case onCloseButtonTapped
#if DEBUG
		case _reset
#endif
		case delegate(Delegate)

		public enum Delegate: Equatable {
			case close
		}
	}

	public init() {

	}

	public var body: some ReducerProtocol<State, Action> {
		Reduce { _, action in
			switch action {
			case .onCloseButtonTapped:
				return .send(.delegate(.close))
			case .delegate:
				return .none
#if DEBUG
			case ._reset:
				return .none
#endif
			}
		}
	}
}

public struct Settings: View {
	@Environment(\.colorScheme) var colorScheme
	let store: StoreOf<SettingsFeature>
	@ObservedObject var viewStore: ViewStore<SettingsFeature.State, SettingsFeature.Action>

	public init(store: StoreOf<SettingsFeature>) {
		self.store = store
		self.viewStore = ViewStore(self.store, observe: {$0})
	}

	public var body: some View {
		VStack {
			HStack {
				Spacer()
				Button(action: { viewStore.send(.onCloseButtonTapped, animation: .default) }) {
					Image(systemName: "xmark")
				}
			}
			.font(.system(size: 24))
			.padding([.top, .leading, .trailing])

			VStack(alignment: .leading, spacing: .grid(4)) {
				Text("Settings")
					.font(.title)
				Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
					.font(.subheadline)
//					.foregroundColor(Color.black)
					.font(.system(size: 16))
					.multilineTextAlignment(.leading)
				Spacer()
				ScrollView(.vertical, showsIndicators: false) {
					VStack(alignment: .leading, spacing: .grid(8)) {
						VStack(spacing: .grid(8)) {
							SettingCell {
								Button(action: {
									self.onReachOutViaEmail()
								}, label: {
									Text("Reach out")
									Spacer()
									Image(systemName: "arrow.right")
										.padding(.trailing, .grid(1))
								})
							}
#if DEBUG
							SettingCell {
								Button(action: {
									viewStore.send(._reset)
								}, label: {
									Text("RESET")
										.foregroundColor(.red)
									Spacer()
								})
							}
#endif
							//							SettingCell {
							//								Button(action: {
							//									self.onCredits()
							//								}, label: {
							//									Text("GitHub")
							//									Spacer()
							//									Image(systemName: "arrow.right")
							//										.padding(.trailing, .grid(1))
							//								})
							//							}
						}
						.padding(16)
						VStack(alignment: .leading, spacing: .grid(1)) {
							Text("Terms / Privacy")
								.fontWeight(.semibold)
								.font(.footnote)
							Text("Version: \(UIApplication.appVersion)")
								.fontWeight(.thin)
								.multilineTextAlignment(.leading)
								.font(.footnote)
						}
						.padding()
						Spacer()
					}
				}
			}
			.padding(EdgeInsets(top: .grid(12), leading: .grid(4), bottom: .grid(4), trailing: .grid(4)))

		}
		.foregroundColor(self.colorScheme == .dark ? .photoGuesserCream : .black)
		.background(
			(self.colorScheme == .dark ? .black : Color.photoGuesserCream)
				.ignoresSafeArea()
		)
	}
	private func onOpenSystemSettings() {
		guard let stringURL = URL(string: UIApplication.openSettingsURLString) else { return }
		UIApplication.shared.open(stringURL)
	}

	private func onReachOutViaEmail() {
		let mail = "sergheevdev@icloud.com"
		if let emailUrl = URL(string: "mailto:\(mail)") {
			UIApplication.shared.open(emailUrl, options: [:], completionHandler: nil)
		}
	}

	private func onCredits() {
		if let supportUrl = URL(string: "https://www.photoguessr.com") {
			UIApplication.shared.open(supportUrl)
		}
	}
}

struct SettingCell<Content: View>: View {
	var content: () -> Content
	init(@ViewBuilder content: @escaping () -> Content) {
		self.content = content
	}
	var body: some View {
		ZStack {
			VStack(alignment: .leading, spacing: .grid(2)) {
				self.content()
				Divider()
					.background(Color.black)
					.frame(height: 2)
			}
		}
	}
}

public extension UIApplication {
	static var appVersion: String {
		let versionNumber = Bundle.main.infoDictionary?[IdentifierConstants.InfoPlist.versionNumber] as? String
		let buildNumber = Bundle.main.infoDictionary?[IdentifierConstants.InfoPlist.buildNumber] as? String

		let formattedBuildNumber = buildNumber.map {
			return "(\($0))"
		}

		return [versionNumber, formattedBuildNumber].compactMap { $0 }.joined(separator: " ")
	}
}

struct IdentifierConstants {
	struct InfoPlist {
		static let versionNumber = "CFBundleShortVersionString"
		static let buildNumber = "CFBundleVersion"
	}
}

#if DEBUG
struct Settings_Previews: PreviewProvider {
	static var previews: some View {
		Preview {
			Settings(
				store: .init(
					initialState: .init(),
					reducer: SettingsFeature()
				)
			)
		}
	}
}
#endif
