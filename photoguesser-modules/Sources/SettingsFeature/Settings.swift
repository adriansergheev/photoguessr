import SwiftUI
import Build
import Foundation
import Styleguide
import Dependencies
import UIApplicationClient
import ComposableGameCenter
import ComposableArchitecture

public struct UserSettings: Equatable {
	public var colorScheme: ColorScheme

	public init(colorScheme: ColorScheme) {
		self.colorScheme = colorScheme
	}

	public enum ColorScheme: String, CaseIterable {
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

public struct SettingsFeature: Reducer {
	public struct State: Equatable {
		var user: Player?
		var buildNumber: Build.Number?
		@BindingState var userSettings: UserSettings
		public init(
			user: Player? = nil,
			userSettings: UserSettings = .init(colorScheme: .light)
		) {
			self.user = user
			self.userSettings = userSettings
		}
	}

	public enum Action: BindableAction, Equatable {
		case binding(BindingAction<State>)
		case task
		case onCloseButtonTapped
		case reportABugButtonTapped
		case termsAndPrivacyButtonTapped
		case leaveReviewButtonTapped
		case delegate(Delegate)

		public enum Delegate: Equatable {
			case close
		}
	}

	@Dependency(\.gameCenter) var gameCenter
	@Dependency(\.build) var build
	@Dependency(\.applicationClient) var applicationClient

	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
			switch action {
			case .task:
				state.buildNumber = self.build.number()
				state.user = gameCenter.localPlayer.localPlayer().player
				return .none
			case .onCloseButtonTapped:
				return .send(.delegate(.close))
			case .reportABugButtonTapped:
				return .fireAndForget { [currentPlayer = state.user] in
					var components = URLComponents()
					components.scheme = "mailto"
					components.path = "sergheevdev@icloud.com"
					components.queryItems = [
						URLQueryItem(name: "subject", value: "I found a bug in photoguessr"),
						URLQueryItem(
							name: "body",
							value: """
 ---
 Build: \(self.build.number())
 \(currentPlayer?.gamePlayerId ?? "")
 """
						)
					]

					_ = await self.applicationClient.open(components.url!, [:])
				}
			case .termsAndPrivacyButtonTapped:
				return .fireAndForget {
					_ = await self.applicationClient
						.open(URL(string: "http://www.photoguessr.com/terms-privacy")!, [:])
				}
			case .leaveReviewButtonTapped:
				return .fireAndForget {
					_ = await self.applicationClient
						.open(URL(string: "https://apps.apple.com/app/photoguessr/id6447366892?action=write-review")!, [:])
				}
			case .binding(\.$userSettings.colorScheme):
				return .fireAndForget { [style = state.userSettings.colorScheme.userInterfaceStyle] in
					await self.applicationClient.setUserInterfaceStyle(style)
				}
			case .binding:
				return .none
			case .delegate:
				return .none
			}
		}
		BindingReducer()
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
					.font(.system(size: 46))
				if let user = viewStore.user {
					Text("\(user.displayName)")
						.font(.subheadline)
						.font(.system(size: 16))
						.multilineTextAlignment(.leading)
				}
				Spacer()
				ScrollView(.vertical, showsIndicators: false) {
					VStack(alignment: .leading, spacing: .grid(8)) {
						VStack(spacing: .grid(8)) {
							SettingCell {
								VStack {
									HStack {
										Text("Appearance")
										Spacer()
									}
									ColorSchemePicker(
										colorScheme: self.viewStore.binding(\.$userSettings.colorScheme)
									)
								}
							}
							SettingCell {
								Button {
									viewStore.send(.leaveReviewButtonTapped)
								} label: {
									Text("Leave a review ✨")
									Spacer()
									Image(systemName: "arrow.right")
										.padding(.trailing, .grid(1))
								}
							}
							SettingCell {
								Button {
									viewStore.send(.termsAndPrivacyButtonTapped)
								} label: {
									Text("Terms / Privacy")
									Spacer()
									Image(systemName: "arrow.right")
										.padding(.trailing, .grid(1))
								}
							}
						}
						.padding(.grid(4))

						VStack(alignment: .leading, spacing: .grid(1)) {
							if let buildNumber = self.viewStore.buildNumber {
								Text("Build \(buildNumber.rawValue)")
									.fontWeight(.thin)
									.multilineTextAlignment(.leading)
									.font(.footnote)
							}
							Button {
								viewStore.send(.reportABugButtonTapped)
							} label: {
								Text("Report a bug")
									.fontWeight(.thin)
									.underline()
									.font(.footnote)
								Spacer()
							}
						}
						.padding()
						Spacer()
					}
				}
			}
			.padding(.grid(4))
		}
		.foregroundColor(self.colorScheme == .dark ? .photoGuesserCream : .black)
		.background(
			(self.colorScheme == .dark ? .black : Color.photoGuesserCream)
				.ignoresSafeArea()
		)
		.task { await self.viewStore.send(.task).finish() }
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
