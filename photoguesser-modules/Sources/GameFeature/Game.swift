import SharedModels
import Foundation
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

		var score: Int = 0
		var gamePhotos: GamePhotos?
		var currentInGamePhoto: Photo?

		var gameNotification: GameNotification.State?
		var slider: CustomSlider.State?

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
		public init(
			score: Int = 0,
			gameNotification: GameNotification.State? = nil,
			slider: CustomSlider.State? = nil
		) {
			self.score = score
			self.gameNotification = gameNotification
			self.slider = slider
		}
	}

	public enum Action: Equatable {
		case startGame
		case gamePhotosResponse(TaskResult<State.GamePhotos>)
		case toggleSlider
		case onSettingsTap

		case slider(CustomSlider.Action)
		case gameNotification(GameNotification.Action)
	}

	@Dependency(\.apiClient) var apiClient

	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
			switch action {
			case .startGame:
				state.score = 0
				state.gamePhotos = nil
				state.currentInGamePhoto = nil

				// Stockholm
				let req = NearestPhotoRequest(
					geo: [59.32938, 18.06871],
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
							// TODO: Execute this at a later time, so a delay effect is observed.
							state.currentInGamePhoto = value
							state.gamePhotos = NearestPhotosResponse(result: .init(photos: gamePhotos), rid: rid)
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
			case .onSettingsTap:
				//TODO: Fix
				return .none
			}
		}
		.ifLet(\.slider, action: /Action.slider) {
			CustomSlider()
		}
		.ifLet(\.gameNotification, action: /Action.gameNotification) {
			GameNotification()
		}
	}
}
