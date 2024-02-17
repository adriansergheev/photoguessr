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
import XCTestDynamicOverlay
import ComposableArchitecture

public struct Game: ReducerProtocol {
	public struct State: Equatable {
		var score: Int = 0
		var mode: State.GameMode
		var gameLocation: GameLocation
		var currentInGamePhoto: Photo?

		var guess: Int
		var guessRange: ClosedRange<Int>
		var isSubmitButtonEnabled: Bool

		var navigationBar: GameNavigationBar.State
		var gameNotification: GameNotification.State?
		var gameOver: GameOver.State?
		var bottomMenu: BottomMenuState<Action>?

		public init(
			score: Int = 0,
			mode: GameMode = .limited(max: 10, current: 0),
			gameLocation: GameLocation,
			gameNotification: GameNotification.State? = nil,
			guess: Int = 1950,
			guessRange: ClosedRange<Int> = 1900...2000,
			isSubmitButtonEnabled: Bool = true
		) {
			self.score = score
			self.mode = mode
			self.gameLocation = gameLocation
			self.gameNotification = gameNotification
			self.guess = guess
			self.guessRange = guessRange
			self.navigationBar = .init(title: gameLocation.name)
			self.isSubmitButtonEnabled = isSubmitButtonEnabled
		}
	}

	public enum Action: Equatable {
		case startGame
		case gamePhotosResponse(TaskResult<GameLocation.GamePhotos>)

		case gameNotification(GameNotification.Action)
		case gameNavigationBar(GameNavigationBar.Action)
		case gameOver(GameOver.Action)

		case sliderValueChanged(Int)
		case submitTapped
		case submitDelayElapsed

		case dismissBottomMenu
		case endGame
		case delegate(Delegate)

		public enum Delegate {
			case close
		}
	}

	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.apiClient) var apiClient
	@Dependency(\.userDefaults) var userDefaults
	@Dependency(\.prefetcher) var prefetcher
	@Dependency(\.feedbackGenerator) var feedbackGenerator

	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		CombineReducers {
			Scope(state: \.navigationBar, action: /Action.gameNavigationBar) {
				GameNavigationBar()
			}
			Reduce { state, action in
				switch action {
				case .startGame:
					let seenKey = userDefaults.integerForKey(seenKey)
					let except = (seenKey == 0) ? nil : seenKey
					return .task { [location = state.gameLocation.location] in
						let request = PastvuPhotoRequest(
							geo: [location.lat, location.long],
							except: except
						)
						return await .gamePhotosResponse(
							TaskResult {
								let response = try await self.apiClient.giveNearestPhotos(request)
								let stripe: (String) -> String = { string in
									// if string has cyrillic in it, drop it
									// swiftlint:disable next opening_brace
									if string.firstMatch(of: #/\p{script=cyrillic}/#) != nil {
										return ""
									}
									var copy = string
									// if string has 4 digits in it, it is probably a year so stripe it
									copy.replace(#/\b\d {4}\b/#, with: "")
									return copy
								}

								let photos = response.result.photos.map { photo in
									var copy = photo
									copy.title = stripe(copy.title)
									return copy
								}

								return PastvuPhotoResponse(
									result: .init(photos: photos),
									rid: response.rid
								)
							}
						)
					}
				case let .gamePhotosResponse(.success(gamePhotos)):
					switch state.mode {
					case let .limited(max: max, current: _):
						var array = gamePhotos.result.photos.shuffled().prefix(max).map { $0 }
						switch state.mode {
						case let .limited(max: _, current: current):
							state.mode = .limited(max: array.count, current: current)
						}
						if let index = array.indices.randomElement() {
							let value = array.remove(at: index)
							state.currentInGamePhoto = value
						}
						state.gameLocation.gamePhotos = PastvuPhotoResponse(
							result: .init(photos: array),
							rid: gamePhotos.rid
						)
						return .fireAndForget { [urls = array.compactMap { $0.imageUrl}] in
							await prefetcher.prefetchImages(urls)
						}
					}
				case .gamePhotosResponse(.failure):
					return .none
				case let .sliderValueChanged(value):
					state.guess = value
					return .none
				case .submitTapped:
					state.isSubmitButtonEnabled = false
					return .task {
						try? await self.mainQueue.sleep(for: .seconds(.random(in: 0.5...1)))
						return .submitDelayElapsed
					}
				case .submitDelayElapsed:
					defer { state.isSubmitButtonEnabled = true }
					guard let photoInPlay = state.currentInGamePhoto else {
						XCTFail("Can't submit picture when currentInGamePhoto is nil")
						return .none
					}
					let score = State.Scoring.score(target: photoInPlay.year, guess: state.guess)

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
						state.gameOver = .init(score: state.score)
					}

					return .fireAndForget { [photoInPlay] in
						await feedbackGenerator.selectionChanged()
						await markAsSeen(id: photoInPlay.cid)
					}
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
						.fireAndForget { await prefetcher.cancelPrefetching() }
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
							.fireAndForget { await prefetcher.cancelPrefetching() }
						)
					}
				case .delegate:
					return .none
				}
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
		await userDefaults.setInteger(id, seenKey)
	}
}
let seenKey = "photoSeenKey"

extension Game.State {
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
	var isEmptyState: Bool {
		gameLocation.imageUrls?.isEmpty ?? false
	}
}

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
		let guess: Int
		let guessRange: ClosedRange<Int>
		let isSubmitButtonEnabled: Bool
		let score: Int
		let mode: Game.State.GameMode
		let gameLocation: GameLocation
		let currentInGamePhoto: Photo?
		let isEmptyState: Bool

		init(state: Game.State) {
			self.guess = state.guess
			self.guessRange = state.guessRange
			self.isSubmitButtonEnabled = state.isSubmitButtonEnabled
			self.score = state.score
			self.mode = state.mode
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
							.adaptiveFont(.cormorantBold, size: 24)
							.padding(.leading, .grid(4))
						Spacer()
						switch viewStore.mode {
						case let .limited(max: limit, current: current):
							Text("\(current)/\(limit)")
								.adaptiveFont(.cormorantBold, size: 24)
								.foregroundColor((limit - current == 1) ? .red : .adaptiveBlack)
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

							VStack(alignment: .center) {
								GameImageView(imageUrl)
								VStack {
									HStack {
										Text(photo.title)
											.lineLimit(2)
											.adaptiveFont(.cormorantBold, size: 17)
											.foregroundColor(Color.adaptiveBlack)
										Spacer()
										Text(verbatim: "\(viewStore.guess)")
											.foregroundColor(.adaptiveBlack)
											.adaptiveFont(.cormorantBold, size: 24)
									}
									.padding([.top, .leading, .trailing], .grid(2))

									ValueSlider(
										value: viewStore.binding(get: \.guess, send: Game.Action.sliderValueChanged),
										in: viewStore.guessRange,
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
										HStack {
											Group {
												if viewStore.isSubmitButtonEnabled {
													Text("Submit")
														.adaptiveFont(.cormorantBold, size: 17)
												} else {
													ProgressView()
														.tint(.adaptiveWhite)
												}
											}
										}
										.frame(width: 80, height: 28)
										.padding(.grid(3))
										.padding([.leading, .trailing], .grid(1))
										.foregroundColor(self.colorScheme == .dark ? .black : .photoGuesserCream)
										.background(self.colorScheme == .dark ? Color.photoGuesserCream : .black)
										.cornerRadius(36)
										.padding(.bottom, .grid(10))
									}
									.disabled(!viewStore.isSubmitButtonEnabled )
								}
								.frame(height: UIScreen.height / 3.8)
								.background(
									.ultraThinMaterial.opacity(1),
									in: RoundedRectangle(cornerRadius: 0, style: .continuous)
								)
							}
						}
						.edgesIgnoringSafeArea(.bottom)
					} else {
						Spacer()
						if viewStore.isEmptyState {
							Text("Could not find any pics for this location ;(")
								.adaptiveFont(.cormorantMedium, size: 17)
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
			.zIndex(2)
		}
		.bottomMenu(self.store.scope(state: \.bottomMenu))
		.background(colorScheme == .dark ? .black : .photoGuesserCream)
	}
}

public struct GameImageView: View {
	let imageUrl: URL

	@State private var previousMagnification = 0.0
	@State private var currentMagnification = 0.0
	@State private var totalMagnification = 1.0

	@State private var offset = CGSize.zero
	@State private var lastOffset = CGSize.zero

	init(_ imageUrl: URL) {
		self.imageUrl = imageUrl
	}

	public var body: some View {
		GeometryReader { proxy in
			VStack {
				Spacer()
				LazyImage(url: imageUrl, transaction: .init(animation: .default)) {
					$0.image?.resizable()
						.aspectRatio(contentMode: .fit)
					// hides the watermark, can be used to guess the year
						.mask(Rectangle().padding(.bottom, 20))
						.frame(width: proxy.size.width, height: proxy.size.height)
						.scaleEffect(self.currentMagnification + self.totalMagnification)
						.offset(self.offset)
						.gesture(
							DragGesture()
								.onChanged { gesture in
									let calculatedOffset = CGSize(
										width: lastOffset.width + gesture.translation.width,
										height: lastOffset.height + gesture.translation.height
									)

									// do not let the image escape the view
									if (abs(calculatedOffset.width) * 1.5 < proxy.size.width),
										 (abs(calculatedOffset.height) * 1.5 < proxy.size.height) {
										self.offset = calculatedOffset
									}
								}
								.onEnded { _ in
									withAnimation {
										self.lastOffset = self.offset
									}
								}
						)
						.gesture(
							MagnifyGesture()
								.onChanged { value in
									let delta = value.magnification / self.previousMagnification
									self.previousMagnification = value.magnification

									if abs(1 - delta) > 0.01 {
										self.currentMagnification = value.magnification - 1
									}
								}
								.onEnded { _ in
									self.totalMagnification += self.currentMagnification
									self.currentMagnification = 0

									if (self.totalMagnification <= 0.8) {
										withAnimation {
											self.totalMagnification = 0.8
										}
									}
								}
						)
						.accessibilityZoomAction { action in
							switch action.direction {
							case .zoomIn:
								self.totalMagnification += 0.5
							case .zoomOut:
								self.totalMagnification -= 1
							}
						}
				}
				.onCompletion { _ in
					self.previousMagnification = 0.0
					self.currentMagnification = 0.0
					self.totalMagnification = 1.0
					self.offset = CGSize.zero
					self.lastOffset = CGSize.zero
				}
				.padding([.top, .bottom], .grid(1))
				Spacer()
			}
		}
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
					initialState: Game.State(
						score: 0,
						gameLocation: .init(location: .init(lat: 55.67594, long: 12.56553), name: "Copenhagen"),
						gameNotification: .init(text: "You nailed it! \(50) points!")
					),
					reducer: Game()
				)
			)
		}
	}
}
#endif
