import SwiftUI
import Styleguide
import CoreLocation
import ComposableArchitecture

struct Location {
	typealias Coordinate = Double

	let lat: Coordinate
	let long: Coordinate
}

struct City: Identifiable {
	let location: Location
	let name: String

	// revisit for uniqueness
	var id: Double { 360 * round(location.lat) + round(location.long) }
}

let cities = [
	City(location: .init(lat: 0, long: 0), name: "San-Francisco"),
	City(location: .init(lat: 59.32938, long: 18.06871), name: "Stockholm"),
	City(location: .init(lat: 47.003670, long: 28.907089), name: "Chisinau")
]

enum CitySection: Identifiable {
	var id: Double {
		switch self {
		case .upgradeBanner:
			return Double.random(in: 0...1000) // fix
		case let .city(city):
			return city.id
		}
	}

	case city(City)
	case upgradeBanner
}

struct Sections {
	var sections: [CitySection]
	init() {
		self.sections = cities.map(CitySection.city)
		self.sections.append(.upgradeBanner)
	}
}

let sfLady = UIImage(named: "sf-lady", in: Bundle.module, with: nil)!

struct Cities: View {
	@Environment(\.colorScheme) var colorScheme
	var body: some View {
		GeometryReader { proxy in
			ScrollView {
				LazyVStack {
					ForEach(Binding(get: { Sections().sections }, set: { _ in })) { section  in
						ZStack {
							VStack {
								switch section.wrappedValue {
								case let .city(_):
									Image(uiImage: sfLady)
										.resizable()
										.aspectRatio(contentMode: .fill)
								case .upgradeBanner:
									Button {
										//
									} label: {
										Text("Add your own city")
											.border(.red)
									}
								}
							}
							.frame(height: proxy.size.height / 4)
							.cornerRadius(8)
							.padding([.leading, .trailing], .grid(4))
							.padding([.top, .bottom], .grid(2))

							VStack {
								Spacer()
								HStack {
									Spacer()
									if case let .city(city) = section.wrappedValue {
										Text(city.name)
											.bold()
											.padding(.grid(2))
											.padding([.leading, .trailing], .grid(2))
											.foregroundColor(self.colorScheme == .dark ? .black : .photoGuesserCream)
											.background(self.colorScheme == .dark ? Color.photoGuesserCream : .black)
											.clipShape(
												RoundedRectangle(cornerRadius: 13, style: .continuous)
													.inset(by: 2)
											)
									}
								}
							}
							.padding([.trailing], .grid(8))
							.padding([.bottom], .grid(4))
						}
						.onTapGesture {
							//
						}
					}
				}
			}
		}
	}
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		Preview {
			Cities()
		}
	}
}
#endif
