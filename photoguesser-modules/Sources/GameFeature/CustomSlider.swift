import SwiftUI
import Styleguide
import Sliders
import ComposableArchitecture

public struct CustomSlider: ReducerProtocol {
	public struct State: Equatable {
		var sliderValue: Double
		var range: ClosedRange<Int>
		fileprivate var sliderRange: ClosedRange<Double> {
			Double(self.range.lowerBound)...Double(self.range.upperBound)
		}

		public init(sliderValue: Double, range: ClosedRange<Int> = 1826...2000) {
			self.sliderValue = sliderValue
			self.range = range
		}
	}

	public enum Action: Equatable {
		case submitTapped
		case sliderValueChanged(Double)
		case delegate(Delegate)

		public enum Delegate {
			case submit
		}
	}

	init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .submitTapped:
			return .send(.delegate(.submit))
		case let .sliderValueChanged(value):
			state.sliderValue = value
			return .none
		case .delegate:
			return .none
		}
	}
}

public struct CustomSliderView: View {
	public let store: StoreOf<CustomSlider>

	public init(store: StoreOf<CustomSlider>) {
		self.store = store
	}

	public var body: some View {
		WithViewStore(self.store, observe: { $0 }) { viewStore in
			VStack {
				ValueSlider(
					value: viewStore.binding(get: \.sliderValue, send: CustomSlider.Action.sliderValueChanged),
					in: viewStore.sliderRange,
					step: 1
				)
				.valueSliderStyle(
					HorizontalValueSliderStyle(
						track: Color.photoGuesserGold
							.opacity(0.5)
							.frame(height: 6)
							.cornerRadius(3),
						thumbSize: CGSize(width: 48, height: 24),
						options: .interactiveTrack
					)
				)
				.padding([.leading, .trailing], .grid(4))
				Button {
					viewStore.send(.submitTapped)
				} label: {
					Text("Submit")
						.foregroundColor(.black)
						.padding(.grid(2))
						.padding([.leading, .trailing], .grid(1))
						.background(Color.photoGuesserCream)
						.cornerRadius(36)
						.foregroundColor(.photoGuesserCream)
						.padding(.bottom, .grid(10))
				}
			}
			.frame(height: .grid(48))
			.background(
				.ultraThinMaterial.opacity(0.8),
				in: RoundedRectangle(cornerRadius: 0, style: .continuous)
			)
		}
	}
}

#if DEBUG
struct CustomSlider_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			Spacer()
			CustomSliderView(
				store: .init(
					initialState: CustomSlider.State(sliderValue: 1950, range: 1900...2000),
					reducer: CustomSlider()
				)
			)
		}
	}
}
#endif
