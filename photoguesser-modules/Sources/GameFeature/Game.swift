import Nuke
import NukeUI
import SwiftUI
import Sliders
import Haptics
import GameOver
import Foundation
import BottomMenu
import Styleguide
import SharedModels
import ApiClientLive
import PrefetcherClient
import GameNotification
import UserDefaultsClient
import ComposableArchitecture

public struct Game: ReducerProtocol {
	public struct State: Equatable {
		public enum GameMode: Equatable {
			case limited(max: Int, current: Int)
		}
		enum Scoring {
			private enum ScoreBounds: Int {
				case max = 50 // max score
				case maxInRange = 40 // max score for ranged guess
			}

			case max(Int)
			case calculated(Int, targetYear: Int)

			case maxInRange(Int)
			case calculatedInRange(Int, lowerBound: Int, upperBound: Int)

			static func score(target: Photo.Year, guess: Int) -> Self {
				switch target {
				case let .year(targetYear):
					switch guess {
					case targetYear:
						return .max(ScoreBounds.max.rawValue)
					default:
						let distance = abs(targetYear - guess)
						let score = Swift.max(0, ScoreBounds.max.rawValue - distance * 2)
						return .calculated(score, targetYear: targetYear)
					}
				case let .range(lowerBound: lowerBound, upperBound: upperBound):
					let targetRange = lowerBound...upperBound
					let isContained = targetRange ~= guess
					if isContained {
						return .maxInRange(ScoreBounds.maxInRange.rawValue)
					} else {
						let targetYear = (lowerBound + upperBound) / 2
						let distance = abs(targetYear - guess)
						let score = Swift.max(0, ScoreBounds.maxInRange.rawValue - distance * 2)
						return .calculatedInRange(score, lowerBound: lowerBound, upperBound: upperBound)
					}
				}
			}
		}

		var score: Int = 0
		var mode: State.GameMode
		var gameLocation: GameLocation
		var currentInGamePhoto: Photo?

		var navigationBar = GameNavigationBar.State()
		var gameNotification: GameNotification.State?
		var slider: CustomSlider.State?
		var gameOver: GameOver.State?
		var bottomMenu: BottomMenuState<Action>?

		public init(
			score: Int = 0,
			mode: GameMode = .limited(max: 10, current: 0),
			gameLocation: GameLocation = .init(location: .init(lat: 55.67594, long: 12.56553), name: "Copenhagen"),
			gameNotification: GameNotification.State? = nil,
			slider: CustomSlider.State? = nil
		) {
			self.score = score
			self.mode = mode
			self.gameLocation = gameLocation
			self.gameNotification = gameNotification
			self.slider = slider
		}
	}

	public enum Action: Equatable {
		case startGame
		case gamePhotosResponse(TaskResult<GameLocation.GamePhotos>)
		case toggleSlider

		case slider(CustomSlider.Action)
		case gameNotification(GameNotification.Action)
		case gameNavigationBar(GameNavigationBar.Action)
		case gameOver(GameOver.Action)

		case dismissBottomMenu
		case endGame
		case delegate(Delegate)

		public enum Delegate {
			case close
		}
	}

	@Dependency(\.apiClient) var apiClient
	@Dependency(\.userDefaults) var userDefaultsClient
	@Dependency(\.prefetcherClient) var prefetcherClient

	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		CombineReducers {
			Scope(state: \.navigationBar, action: /Action.gameNavigationBar) {
				GameNavigationBar()
			}
			Reduce { state, action in
				switch action {
				case .startGame:
					state.score = 0
					// clear out the list before starting
					state.gameLocation.gamePhotos = nil
					state.currentInGamePhoto = nil
					let seenKey = userDefaultsClient.integerForKey(seenKey)
					let except = (seenKey == 0) ? nil : seenKey

					return .task { [location = state.gameLocation.location] in
						let request = PastvuPhotoRequest(
							geo: [location.lat, location.long],
							limit: 100,
							except: except
						)
						return await .gamePhotosResponse(
							TaskResult { try await self.apiClient.giveNearestPhotos(request) }
						)
					}
				case let .gamePhotosResponse(.success(gamePhotos)):
					switch state.mode {
					case let .limited(max: max, current: _):
						var array = gamePhotos.result.photos.shuffled().prefix(max).map { $0 }
						if let index = array.indices.randomElement() {
							let value = array.remove(at: index)
							state.currentInGamePhoto = value
						}
						state.gameLocation.gamePhotos = PastvuPhotoResponse(
							result: .init(photos: array),
							rid: gamePhotos.rid
						)
						return .fireAndForget { [urls = array.compactMap { $0.imageUrl}] in
							await prefetcherClient.prefetchImages(urls)
						}
					}
				case .gamePhotosResponse(.failure):
					return .none
				case .toggleSlider:
					state.slider = state.slider == nil ? CustomSlider.State(sliderValue: 1913, range: 1826...2000) : nil
					return .none
				case .slider(.delegate(.submit)):
					guard
						let guess = state.guess,
						let photoInPlay = state.currentInGamePhoto
					else { return .none }
					defer {
						if var gamePhotos = state.gameLocation.gamePhotos?.result.photos,
							 let rid = state.gameLocation.gamePhotos?.rid,
							 !gamePhotos.isEmpty {

							if let index = gamePhotos.indices.randomElement() {
								let value = gamePhotos.remove(at: index)
								state.currentInGamePhoto = value
								state.gameLocation.gamePhotos = PastvuPhotoResponse(result: .init(photos: gamePhotos), rid: rid)
							}

							if case let .limited(max, current) = state.mode {
								if current + 1 >= max {
									state.gameOver = .init(score: state.score)
								} else {
									state.mode = .limited(max: max, current: current + 1)
								}
							}

						} else {
							state.gameOver = .init(score: state.score, reason: .outOfImages)
						}
					}

					let score = State.Scoring.score(target: photoInPlay.year, guess: guess)

					switch score {
					case let .max(score):
						state.score += score
						state.gameNotification = .init(text: "You nailed it! \(score) points!")
					case let .maxInRange(score):
						state.score += score
						state.gameNotification = .init(text: "Your guess is within the range!\(score) points!")
					case let .calculated(score, targetYear):
						state.score += score
						state.gameNotification = .init(text: "Photo was taken in \(targetYear)\n\(score) points!")
					case let .calculatedInRange(score, lowerBound, upperBound):
						state.score += score
						state.gameNotification = .init(text: "Photo was taken between \(lowerBound) and \(upperBound)\n\(score) points!")
					}

					return .fireAndForget { [photoInPlay] in
						await markAsSeen(id: photoInPlay.cid)
					}
				case .slider:
					return .none
				case .gameNotification(.onAppear):
					return .none
				case .gameNotification(.didExpire):
					state.gameNotification = nil
					return .none
				case .gameNavigationBar(.onMenuButtonTapped):
					state.bottomMenu = .endGameMenu(state: state)
					return .none
				case .gameOver(.delegate(.close)):
					state.gameOver = nil
					return .merge(
						.send(.delegate(.close)),
						.fireAndForget { await prefetcherClient.cancelPrefetching() }
					)
				case .gameOver:
					return .none
				case .dismissBottomMenu:
					state.bottomMenu = nil
					return .none
				case .endGame:
					if !(state.score == 0) {
						state.gameOver = .init(score: state.score)
						return .none
					} else {
						return .merge(
							.send(.delegate(.close)),
							.fireAndForget { await prefetcherClient.cancelPrefetching() }
						)
					}
				case .delegate:
					return .none
				}
			}
			.ifLet(\.slider, action: /Action.slider) {
				CustomSlider()
			}
			.ifLet(\.gameNotification, action: /Action.gameNotification) {
				GameNotification()
			}
			.ifLet(\.gameOver, action: /Action.gameOver) {
				GameOver()
			}
			.haptics(triggerOnChangeOf: \.guess)
			.haptics(triggerOnChangeOf: \.score)
		}
	}

	// TODO: Support more
	func markAsSeen(id: Int) async {
		await userDefaultsClient.setInteger(id, seenKey)
	}
}

extension Game.State {
	var guess: Int? {
		get {
			if let sliderValue = slider?.sliderValue {
				return Int(sliderValue)
			} else {
				return nil
			}
		}
		set { if let newValue { slider?.sliderValue = Double(newValue) } }
	}

	var isEmptyState: Bool {
		gameLocation.imageUrls?.isEmpty ?? false
	}
}

let seenKey = "photoSeenKey"

extension BottomMenuState where Action == Game.Action {
	public static func endGameMenu(state: Game.State) -> Self {
		var menu = BottomMenuState(
			title: .init(""),
			message: .init("Are you sure you want to exit the game?"),
			buttons: [
				.init(title: .init("Keep Playing"), icon: Image(systemName: "arrowtriangle.right"))
			],
			footerButton: .init(
				title: .init("End Game"),
				icon: Image(systemName: "flag"),
				action: .init(action: .endGame, animation: .default))
		)
		menu.onDismiss = .init(action: .dismissBottomMenu, animation: .default)
		return menu
	}
}

public struct GameView: View {
	public let store: StoreOf<Game>
	@Environment(\.colorScheme) var colorScheme
	@ObservedObject var viewStore: ViewStore<ViewState, Game.Action>

	struct ViewState: Equatable {
		let score: Int
		let guess: Int?
		let mode: Game.State.GameMode
		let slider: CustomSlider.State?
		let gameLocation: GameLocation
		let currentInGamePhoto: Photo?
		let isEmptyState: Bool

		init(state: Game.State) {
			self.score = state.score
			self.guess = state.guess
			self.mode = state.mode
			self.slider = state.slider
			self.gameLocation = state.gameLocation
			self.currentInGamePhoto = state.currentInGamePhoto
			self.isEmptyState = state.isEmptyState
		}
	}

	public init(store: StoreOf<Game>) {
		self.store = store
		self.viewStore = ViewStore(self.store, observe: ViewState.init)
	}

	public var body: some View {
		ZStack {
			VStack {
				GameNavigationBarView(
					store: self.store.scope(
						state: \.navigationBar,
						action: Game.Action.gameNavigationBar
					)
				)
				VStack {
					HStack {
						Text("\(viewStore.score)")
							.foregroundColor(.adaptiveBlack)
							.bold()
							.frame(width: 40)
							.padding(.leading, .grid(4))

						Spacer()
						Text(verbatim: "\(viewStore.guess ?? 0)")
							.foregroundColor(.adaptiveBlack)
							.font(.system(size: 24))
							.bold()
							.opacity(viewStore.guess != nil ? 1.0 : 0.0)
							.transaction { $0.animation = nil }
						Spacer()

						switch viewStore.mode {
//						case .unlimited:
//							Text("♾️")
//								.bold()
//								.frame(width: 40)
//								.padding(.trailing, .grid(4))
						case let .limited(max: limit, current: current):
							Text("\(current)/\(limit)")
								.bold()
								.foregroundColor(.adaptiveBlack)
								.frame(width: 40)
								.padding(.trailing, .grid(4))
						}
					}

					if let photo = viewStore.currentInGamePhoto,
						 let imageUrl = photo.imageUrl {
						ZStack {
							VStack {
								IfLetStore(
									self.store.scope(
										state: \.gameNotification,
										action: Game.Action.gameNotification
									),
									then: { store in
										GameNotificationView(store: store)
											.padding(.grid(2))
									}
								)
								Spacer()
							}
							.zIndex(1)

							VStack(alignment: .leading) {
								Spacer()
								VStack(spacing: .grid(2)) {
									HStack(alignment: .center) {
										Text(photo.title)
											.padding(.grid(2))
											.bold()
											.foregroundColor(Color.adaptiveBlack)
											.background(.ultraThinMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
											.onTapGesture {
												viewStore.send(.toggleSlider, animation: .easeIn)
											}
										Spacer()
										Button {
											viewStore.send(.toggleSlider, animation: .easeIn)
										} label: {
											Image(systemName: "chevron.up")
												.rotationEffect(.degrees(viewStore.slider != nil ? 180 : 0))
												.foregroundColor(.adaptiveBlack)
												.padding(.grid(2))
												.background(.ultraThinMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 36, style: .continuous))
												.padding(.grid(2))
												.padding(.trailing, .grid(2))
										}
										.transaction { $0.animation = nil }
									}
									.padding(.leading, .grid(3))
									.padding(.bottom, viewStore.slider == nil ? .grid(16) : 0)
								}
								IfLetStore(
									self.store.scope(
										state: \.slider,
										action: Game.Action.slider
									),
									then: { store in
										CustomSliderView(store: store)
									}
								)
							}
							.zIndex(1)

							LazyImage(url: imageUrl, transaction: .init(animation: .default)) {
								$0.image
									.aspectRatio(contentMode: .fill)
									.frame(width: 100, height: 100)
							}
						}
						.edgesIgnoringSafeArea(.bottom)
					} else {
						Spacer()
						if viewStore.isEmptyState {
							Text("Could not find any pics for this location ;(")
								.foregroundColor(.adaptiveBlack)
						} else {
							ProgressView()
						}
						Spacer()
					}
				}
				.onAppear {
					viewStore.send(.startGame)
				}
			}
			IfLetStore(
				self.store.scope(state: \.gameOver, action: Game.Action.gameOver),
				then: GameOverView.init(store:)
			)
			.background(Color.adaptiveWhite.ignoresSafeArea())
			.transition(
				.asymmetric(
					insertion: AnyTransition.opacity.animation(.linear(duration: 1)),
					removal: .game
				)
			)
			.zIndex(1)
		}
		.bottomMenu(self.store.scope(state: \.bottomMenu))
		.background(colorScheme == .dark ? .black : .photoGuesserCream)
	}
}
extension AnyTransition {
	public static let game = move(edge: .bottom)
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		Preview {
			GameView(
				store: .init(
					initialState: Game.State(score: 0, gameNotification: .init(text: "You nailed it! \(50) points!")),
					reducer: Game()
				)
			)
		}
	}
}
#endif
