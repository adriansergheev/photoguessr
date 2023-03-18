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
		public let name: String
		// TODO: revisit for uniqueness
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
		case city(City, isLoading: Bool = false)
		case upgradeBanner

		public var id: Double {
			switch self {
			case .upgradeBanner:
				// NB: There can be one upgrade banner only.
				return 1
			case let .city(city, _):
				return city.id
			}
		}
	}

	public struct State: Equatable {
		public var sections: IdentifiedArrayOf<Section>
		public var showPlaceholder: Bool = false

		public init(sections: IdentifiedArrayOf<Section> = [
			.city(City(location: .init(lat: 0, long: 0), name: "San-Francisco"), isLoading: true),
			.city(City(location: .init(lat: 59.32938, long: 18.06871), name: "Stockholm"), isLoading: true),
			.city(City(location: .init(lat: 47.003670, long: 28.907089), name: "Chișinău"), isLoading: true),
			.upgradeBanner
		]) {
			self.sections = sections
		}
	}

	public enum DelegateAction: Equatable {
		case close
		case startGame(City.ID)
	}

	public enum Action: Equatable {
		case onAppear
		case onSectionTap(Section.ID)
		case updateSection(Section)
		case onCloseButtonTapped
		case delegate(DelegateAction)
	}

	@Dependency(\.apiClient) var apiClient
	@Dependency(\.mainQueue) var mainQueue
	public init() {

	}
	public var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
			switch action {
			case .onAppear:
				state.showPlaceholder = true
				return .run { [sections = state.sections] send in
					await withTaskGroup(of: Void.self) { group in
						for section in sections {
							group.addTask {
								if case var .city(city, _) = section {
									let location = city.location
									let req = NearestPhotoRequest(geo: [location.lat, location.long], limit: 10)
									let result = try? await apiClient.giveNearestPhotos(req)
									city.imageUrls = result?.result.photos.compactMap { $0.imageUrl } ?? []
									try? await self.mainQueue.sleep(for: .seconds(0.5))
									await send(.updateSection(.city(city, isLoading: false)))
								}
							}
						}
					}
				}
			case let.onSectionTap(id):
				guard let section = state.sections[id: id] else { return .none }
				switch section {
				case .city:
					return .send(.delegate(.startGame(id)))
				case .upgradeBanner:
					// TODO: Send to upgrade
					return .none
				}
			case let .updateSection(section):
				state.sections.updateOrAppend(section)
				return .none
			case .onCloseButtonTapped:
				return .send(.delegate(.close))
			case .delegate:
				return .none
			}
		}
	}
}

public struct Cities: View {
	@Environment(\.colorScheme) var colorScheme
	let store: StoreOf<CitiesFeature>
	@ObservedObject var viewStore: ViewStore<CitiesFeature.State, CitiesFeature.Action>

	public init(store: StoreOf<CitiesFeature>) {
		self.store = store
		self.viewStore = ViewStore(self.store, observe: {$0})
	}

	public var body: some View {
		VStack(spacing: 0) {
			HStack {
				Spacer()
				Button(action: { viewStore.send(.onCloseButtonTapped, animation: .default) }) {
					Image(systemName: "xmark")
				}
			}
			.font(.system(size: 24))
			.padding()

			GeometryReader { proxy in
				ScrollView {
					LazyVStack {
						ForEach(self.viewStore.sections) { section in
							Button {
								viewStore.send(.onSectionTap(section.id))
							} label: {
								ZStack {
									VStack {
										switch section {
										case let .city(city, isLoading):
											VStack {
												if let imageUrls = city.imageUrls {
													if !imageUrls.isEmpty {
														LazyImage(url: imageUrls.randomElement()) { phase in
															if let image = phase.image {
																image.resizable()
																	.aspectRatio(contentMode: .fill)
															} else {
																ProgressView()
															}
														}
													} else {
														Text("Could not fetch images for this city ;(")
													}
												} else {
													Rectangle()
														.opacity(0.5)
														.redacted(reason: isLoading ? .placeholder : [])
												}
											}
										case .upgradeBanner:
											TextStyle(text: "More cities coming soon!")
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
											if case let .city(city, _) = section {
												TextStyle(text: city.name)
											}
										}
									}
									.padding([.trailing], .grid(8))
									.padding([.bottom], .grid(4))
								}
							}
							.allowsHitTesting(!(section == .upgradeBanner))
						}
					}
				}
			}
			.onAppear { self.viewStore.send(.onAppear) }
		}
		.foregroundColor(self.colorScheme == .dark ? .photoGuesserCream : .black)
		.background(
			(self.colorScheme == .dark ? .black : Color.photoGuesserCream)
				.ignoresSafeArea()
		)
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
