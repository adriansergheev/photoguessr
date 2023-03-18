import SwiftUI
import CitiesFeature

@main
struct CitiesPreviewApp: App {
	var body: some Scene {
		WindowGroup {
			Cities(
				store: .init(
					initialState: .init(
						sections: [
							.city(CitiesFeature.City(location: .init(lat: 0, long: 0), name: "San-Francisco"), isLoading: true), // error state
							.city(CitiesFeature.City(location: .init(lat: 59.32938, long: 18.06871), name: "Stockholm"), isLoading: true),
							.city(CitiesFeature.City(location: .init(lat: 47.003670, long: 28.907089), name: "Chisinau"), isLoading: true),
							.upgradeBanner
						]
					),
					reducer: CitiesFeature()
				)
			)
		}
	}
}
