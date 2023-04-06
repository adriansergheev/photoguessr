import Foundation
import ComposableArchitecture

public struct AppDelegateReducer: ReducerProtocol {

	public struct State: Equatable {
		public init() {}
	}

	public enum Action: Equatable {
		case didFinishLaunching
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce { _, action in
			switch action {
			case .didFinishLaunching:
				return .none
			}
		}
	}
}
