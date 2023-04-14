import SwiftUI
import SharedModels
import Styleguide
import CitiesFeature

@main
struct CitiesPreviewApp: App {

	init() {
		Styleguide.registerFonts()
	}

	var body: some Scene {
		WindowGroup {
			Cities(
				store: .init(
					initialState: .init(
						sections: [
							.city(GameLocation(location: .init(lat: 0, long: 0), name: "San-Francisco")), // error state
							.city(GameLocation(location: .init(lat: 59.32938, long: 18.06871), name: "Stockholm")),
							.city(GameLocation(location: .init(lat: 47.003670, long: 28.907089), name: "Chisinau")),
							.upgradeBanner
						]
					),
					reducer: CitiesFeature()
				)
			)
		}
	}
}
