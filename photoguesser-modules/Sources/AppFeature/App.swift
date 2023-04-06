import SwiftUI
import Foundation
import HomeFeature
import ComposableArchitecture

public struct AppReducer: ReducerProtocol {
	public struct State {
		public var appDelegate: AppDelegateReducer.State
		public var home: Home.State

		public init(
			appDelegate: AppDelegateReducer.State = .init(),
			home: Home.State = .init()
		) {
			self.appDelegate = appDelegate
			self.home = home
		}
	}

	public enum Action: Equatable {
		case appDelegate(AppDelegateReducer.Action)
		case didChangeScenePhase(ScenePhase)
		case home(Home.Action)
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.appDelegate, action: /Action.appDelegate) {
			AppDelegateReducer()
		}
		Scope(state: \.home, action: /Action.home) {
			Home()
		}
		Reduce { _, action in
			switch action {
			case .appDelegate:
				return .none
			case .home:
				return .none
			case .didChangeScenePhase:
				return .none
			}
		}
	}
}

public struct AppView: View {
	let store: StoreOf<AppReducer>

	public init(store: StoreOf<AppReducer>) {
		self.store = store
	}

	public var body: some View {
		Group {
			HomeView(
				store: self.store.scope(
					state: \.home,
					action: AppReducer.Action.home
				)
			)
		}
	}
}
