import Haptics
import GameOver
import Foundation
import SharedModels
import GameNotification
import ComposableArchitecture

extension Photo {
	public var imageUrl: URL? {
		let base = "https://pastvu.com/_p/d/"
		return URL(string: base.appending(self.file))
	}
}

extension Photo {
	public enum Year {
		case year(Int)
		case range(lowerBound: Int, upperBound: Int)
	}

	public var specificYear: Year {
		if let yearUpperBound {
			if yearUpperBound != self.year {
				return .range(lowerBound: self.year, upperBound: yearUpperBound)
			}
		}
		return .year(self.year)
	}
}

public struct Game: ReducerProtocol {

	public struct State: Equatable {
		public typealias GamePhotos = NearestPhotosResponse

		public enum GameMode: Equatable {
			case unlimited
			case limited(max: Int, current: Int)
		}

		var score: Int = 0
		var mode: State.GameMode = .unlimited
		var gamePhotos: GamePhotos?
		var currentInGamePhoto: Photo?

		var navigationBar = GameNavigationBar.State()
		var gameNotification: GameNotification.State?
		var slider: CustomSlider.State?
		var gameOver: GameOver.State?

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

		var isInEmptyState: Bool {
			gamePhotos?.result.photos.isEmpty ?? false
		}

		public init(
			score: Int = 0,
			mode: GameMode = .unlimited,
			gameNotification: GameNotification.State? = nil,
			slider: CustomSlider.State? = nil
		) {
			self.score = score
			self.mode = mode
			self.gameNotification = gameNotification
			self.slider = slider
		}
	}

	public enum Action: Equatable {
		case startGame
		case gamePhotosResponse(TaskResult<State.GamePhotos>)
		case toggleSlider

		case slider(CustomSlider.Action)
		case gameNotification(GameNotification.Action)
		case gameNavigationBar(GameNavigationBar.Action)
		case gameOver(GameOver.Action)
	}

	@Dependency(\.apiClient) var apiClient

	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Scope(state: \.navigationBar, action: /Action.gameNavigationBar) {
			GameNavigationBar()
		}
		Reduce { state, action in
			switch action {
			case .startGame:
				state.score = 0
				state.gamePhotos = nil
				state.currentInGamePhoto = nil

				// Stockholm
				let req = NearestPhotoRequest(
					//					geo: [59.32938, 18.06871] // stockholm
					//					geo: [47.003670, 28.907089], // chisinau
					geo: [55.67594, 12.56553], // copenhagen
					limit: 100,
					except: 228481
				)
				return .task { [req] in
					await .gamePhotosResponse(
						TaskResult { try await self.apiClient.giveNearestPhotos(req) }
					)
				}
			case let .gamePhotosResponse(.success(gamePhotos)):
				var array = gamePhotos.result.photos
				if let index = array.indices.randomElement() {
					let value = array.remove(at: index)
					state.currentInGamePhoto = value
				}
				state.gamePhotos = NearestPhotosResponse(result: .init(photos: array), rid: gamePhotos.rid)
				return .none
			case .gamePhotosResponse(.failure):
				return .none
			case .toggleSlider:
				state.slider = state.slider == nil ? CustomSlider.State(sliderValue: 1913, range: 1826...2000) : nil
				return .none
			case .slider(.submitTapped):
				guard let guess = state.guess, let photoInPlay = state.currentInGamePhoto else { return .none }
				defer {
					if var gamePhotos = state.gamePhotos?.result.photos,
						 let rid = state.gamePhotos?.rid,
						 !gamePhotos.isEmpty {

						if let index = gamePhotos.indices.randomElement() {
							let value = gamePhotos.remove(at: index)
							state.currentInGamePhoto = value
							state.gamePhotos = NearestPhotosResponse(result: .init(photos: gamePhotos), rid: rid)
						}

						if case let .limited(max, current) = state.mode {
							if current + 1 >= 10 {
								state.gameOver = .init()
								state.score = 0
								state.mode = .limited(max: max, current: 0)
							} else {
								state.mode = .limited(max: max, current: current + 1)
							}
						}

					} else {
#if DEBUG
						print("🤠 finished pics")
#endif
					}
				}

				switch photoInPlay.specificYear {
				case let .year(targetYear):
					switch guess {
					case targetYear:
						state.score += 50
						state.gameNotification = .init(text: "You nailed it! \(50) points!")
					default:
						let distance = abs(targetYear - guess)
						let score = max(0, 50 - distance * 2)

						state.score += score
						state.gameNotification = .init(text: "Photo was taken in \(targetYear) which is \(distance) years  away.\nYou received \(score) points")
					}

				case let .range(lowerBound: lowerBound, upperBound: upperBound):
					let targetRange = lowerBound...upperBound
					let isContained = targetRange ~= guess

					if isContained {
						state.score += 40
						state.gameNotification = .init(text: "Your guess is within the range! \(40) points!")
					} else {
						let targetYear = (lowerBound + upperBound) / 2
						let distance = abs(targetYear - guess)
						let score = max(0, 40 - distance * 2)

						state.score += score
						state.gameNotification = .init(text: "Photo was taken between \(lowerBound) and \(upperBound)\n You received \(score) points")
					}
				}
				return .none
			case .slider:
				return .none
			case .gameNotification(.onAppear):
				return .none
			case .gameNotification(.didExpire):
				state.gameNotification = nil
				return .none
			case .gameNavigationBar:
				return .none
			case .gameOver(.onCloseButtonTapped):
				state.gameOver = nil
				return .none
			}
		}
		.ifLet(\.slider, action: /Action.slider) {
			CustomSlider()
		}
		.ifLet(\.gameNotification, action: /Action.gameNotification) {
			GameNotification()
		}
		.haptics(isEnabled: { _ in true }, triggerOnChangeOf: \.guess)
		.haptics(isEnabled: { _ in true }, triggerOnChangeOf: \.score)
	}
}
