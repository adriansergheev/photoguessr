import NukeUI
import SwiftUI
import Styleguide
import CoreLocation
import SharedModels
import ApiClientLive
import IdentifiedCollections
import ComposableArchitecture

public struct CitiesFeature: Reducer {
	public struct City: Equatable, Identifiable {
		public let location: Location
		let name: String
		// revisit for uniqueness
		public var id: Double { 360 * round(location.lat) + round(location.long) }
		public var imageUrls: [URL]?

		public init(location: Location, name: String) {
			self.location = location
			self.name = name
		}
	}
	public struct Location: Equatable {
		public typealias Coordinate = Double

		public let lat: Coordinate
		public let long: Coordinate

		public init(lat: Coordinate, long: Coordinate) {
			self.lat = lat
			self.long = long
		}
	}

	public enum Section: Equatable, Identifiable {
		case city(City)
		case upgradeBanner

		public var id: Double {
			switch self {
			case .upgradeBanner:
				// NB: There can be one upgrade banner only.
				return 1
			case let .city(city):
				return city.id
			}
		}
	}

	public struct State: Equatable {
		public var sections: IdentifiedArrayOf<Section>

		public init(sections: IdentifiedArrayOf<Section> = [
			.city(City(location: .init(lat: 0, long: 0), name: "San-Francisco")),
			.city(City(location: .init(lat: 59.32938, long: 18.06871), name: "Stockholm")),
			.city(City(location: .init(lat: 47.003670, long: 28.907089), name: "Chisinau")),
			.upgradeBanner
		]) {
			self.sections = sections
		}
	}

	public enum Action: Equatable {
		case onAppear
		case onUpgradeTapped
		case updateSection(Section)
	}

	@Dependency(\.apiClient) var apiClient
	public init() {

	}
	public var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
			switch action {
			case .onAppear:
				return .run { [sections = state.sections] send in
					await withTaskGroup(of: Void.self) { group in
						for section in sections {
							group.addTask {
								if case var .city(city) = section {
									let location = city.location
									let req = NearestPhotoRequest(geo: [location.lat, location.long], limit: 10)
									let result = try? await apiClient.giveNearestPhotos(req)
									city.imageUrls = result?.result.photos.compactMap { $0.imageUrl } ?? []
									await send(.updateSection(.city(city)))
								}
							}
						}
					}
				}
			case .onUpgradeTapped:
				return .none
			case let .updateSection(section):
				state.sections.updateOrAppend(section)
				return .none
			}
		}
	}
}

// let sfLady = UIImage(named: "sf-lady", in: Bundle.module, with: nil)!

public struct Cities: View {
	@Environment(\.colorScheme) var colorScheme
	let store: StoreOf<CitiesFeature>
	@ObservedObject var viewStore: ViewStore<CitiesFeature.State, CitiesFeature.Action>

	public init(store: StoreOf<CitiesFeature>) {
		self.store = store
		self.viewStore = ViewStore(self.store, observe: {$0})
	}

	public var body: some View {
		GeometryReader { proxy in
			ScrollView {
				LazyVStack {
					ForEach(self.viewStore.sections) { section  in
						ZStack {
							VStack {
								switch section {
								case let .city(city):
									if let imageUrls = city.imageUrls {
										if !imageUrls.isEmpty {
											AsyncImage(url: imageUrls.first) { phase in
												phase.image?
													.resizable()
													.aspectRatio(contentMode: .fill)
											}
										} else {
											Text("Could not fetch images for this city ;(")
										}
									}
								case .upgradeBanner:
									Button {
										self.viewStore.send(.onUpgradeTapped)
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
									if case let .city(city) = section {
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
		.onAppear { self.viewStore.send(.onAppear) }
	}
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		Preview {
			Cities(
				store: .init(
					initialState: .init(
						sections: [
							.city(CitiesFeature.City(location: .init(lat: 0, long: 0), name: "San-Francisco")),
							.city(CitiesFeature.City(location: .init(lat: 59.32938, long: 18.06871), name: "Stockholm")),
							.city(CitiesFeature.City(location: .init(lat: 47.003670, long: 28.907089), name: "Chisinau")),
							.upgradeBanner
						]
					),
					reducer: CitiesFeature()
				)
			)
		}
	}
}
#endif
