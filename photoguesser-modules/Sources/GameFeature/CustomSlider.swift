import SwiftUI
import Styleguide
import Sliders
import ComposableArchitecture

public struct CustomSlider: ReducerProtocol {

	public struct State: Equatable {
		var sliderValue: Double
		var range: ClosedRange<Int>
		var sliderRange: ClosedRange<Double> {
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
//	@Environment(\.colorScheme) var colorScheme
	public let store: StoreOf<CustomSlider>

	public init(store: StoreOf<CustomSlider>) {
		self.store = store
	}

	public var body: some View {
		WithViewStore(self.store) { viewStore in
			VStack(alignment: .center) {
				Spacer()
				Text(verbatim: "\(Int(viewStore.sliderValue))")
				VStack {
					ValueSlider(
						value: viewStore.binding(get: \.sliderValue, send: CustomSlider.Action.sliderValueChanged),
						in: viewStore.sliderRange,
						step: 1
					)
					.valueSliderStyle(
						HorizontalValueSliderStyle(
							track: Color.adaptiveBlack
								.frame(height: 6).cornerRadius(3),
							thumbSize: CGSize(width: 48, height: 16),
							options: .interactiveTrack
						)
					)
				}
				.frame(height: 36)
				.padding(.bottom, 8)
				.border(.red)
			}
			.frame(height: 96)
//			.background(Color.adaptiveWhite)
			.cornerRadius(5)
			.border(.blue)
		}
	}
}

#if DEBUG
struct CustomSlider_Previews: PreviewProvider {
	static var previews: some View {
		CustomSliderView(
			store: .init(
				initialState: CustomSlider.State.init(sliderValue: 50, range: 0...100),
				reducer: CustomSlider()
			)
		)
	}
}
#endif
