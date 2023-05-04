import NukeUI
import SwiftUI
import Styleguide
import SharedModels
import ApiClientLive
import IdentifiedCollections
import ComposableArchitecture

public func defaults() -> IdentifiedArrayOf<CitiesFeature.Section> {
	var defaults = [
		GameLocation.init(location: CanonicalLocation.init(lat: 59.32, long: 18.06), name: "Stockholm"),
		.init(location: .init(lat: 47.49, long: 19.04), name: "Budapest"),
		.init(location: .init(lat: 60.16, long: 24.93), name: "Helsinki"),
		.init(location: .init(lat: 59.91, long: 10.75), name: "Oslo"),
		.init(location: .init(lat: 37.77, long: -122.41), name: "San-Francisco"),
		.init(location: .init(lat: 41.90, long: 12.49), name: "Rome"),
		.init(location: .init(lat: 35.68, long: 139.69), name: "Tokyo"),
		.init(location: .init(lat: 44.43, long: 26.09), name: "Bucharest"),
		.init(location: .init(lat: 47.01, long: 28.86), name: "Chișinău"),
		.init(location: .init(lat: 48.86, long: 2.34), name: "Paris"),
		.init(location: .init(lat: 40.73, long: -73.93), name: "New-York")
	]
		.map { gameLocation in
			let randomisedLocation = CanonicalLocation(
				lat: gameLocation.location.lat + Double.random(in: 0.00...0.09),
				long: gameLocation.location.long + Double.random(in: 0.00...0.09)
			)
			return GameLocation(location: randomisedLocation, name: gameLocation.name)
		}
		.map { CitiesFeature.Section.city($0, isLoading: true) }
	defaults.append(.upgradeBanner)
	return IdentifiedArray(uniqueElements: defaults)
}

public struct CitiesFeature: Reducer {
	public enum Section: Equatable, Identifiable {
		case city(GameLocation, isLoading: Bool = true)
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
		public init(sections: IdentifiedArrayOf<Section> = defaults()) {
			self.sections = sections
		}
	}

	public enum Action: Equatable {
		case onAppear
		case onSectionTap(Section.ID)
		case updateSection(Section)
		case onCloseButtonTapped
		case delegate(Delegate)

		public enum Delegate: Equatable {
			case close
			case startGame(GameLocation)
		}
	}

	@Dependency(\.apiClient) var apiClient
	@Dependency(\.mainQueue) var mainQueue
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
								if case var .city(city, _) = section {
									let location = city.location
									let request = PastvuPhotoRequest(geo: [location.lat, location.long], limit: 5)
									let result = try? await apiClient.giveNearestPhotos(request)
									city.gamePhotos = result
									await send(.updateSection(.city(city, isLoading: false)))
								}
							}
						}
					}
				}
			case let.onSectionTap(id):
				guard let section = state.sections[id: id] else { return .none }
				switch section {
				case var .city(gameLocation, _):
					if let imageUrls = gameLocation.imageUrls, !imageUrls.isEmpty {
						// re-set the photos for the game instance.
						gameLocation.gamePhotos = nil
						return .send(.delegate(.startGame(gameLocation)))
					} else {
						// TODO: Can't start game, no pics to show at the location
						return .none
					}
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
			.adaptiveFont(.cormorantMedium, size: 24)
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
											if let imageUrls = city.imageUrls {
												LazyImage(url: imageUrls.randomElement()) { phase in
													if let image = phase.image {
														image.resizable()
															.aspectRatio(contentMode: .fill)
													} else {
														ProgressView()
													}
												}
											} else {
												if isLoading {
													//
												} else {
													Text("Could not fetch images for this location ;(")
														.adaptiveFont(.cormorantMedium, size: 17)
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
							.city(GameLocation(location: .init(lat: 0, long: 0), name: "San-Francisco")),
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
#endif
