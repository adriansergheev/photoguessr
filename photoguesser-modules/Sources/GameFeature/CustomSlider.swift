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
		init(sliderValue: Double, range: ClosedRange<Int> = 1826...2000) {
			self.sliderValue = sliderValue
			self.range = range
		}
	}

	public enum Action: Equatable {
		case sliderValueChanged(Double)
	}

	init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .sliderValueChanged(value):
			state.sliderValue = value
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
		WithViewStore(self.store) { viewStore in
			VStack(alignment: .center) {
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
							thumbSize: CGSize(width: 48, height: 16),
							options: .interactiveTrack
						)
					)
				}
			}
			.frame(height: .grid(48))
			.background(
				.ultraThinMaterial,
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
					initialState: CustomSlider.State.init(sliderValue: 1950, range: 1900...2000),
					reducer: CustomSlider()
				)
			)
		}
	}
}
#endif
