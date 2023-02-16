import SharedModels
import Foundation
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

		var guess: Int?
		var score: Int = 0
		var gamePhotos: GamePhotos?
		var currentInGamePhoto: Photo?
		var alert: AlertState<Action>?

		var showSubmitGuide: Bool = false
		var timerSecondsElapsed: Int = 0
		var timerInterval: Int = 5
		var isTimerActive: Bool = false

		fileprivate var range: ClosedRange<Int> = 1826...2000

		// TODO: Move slider range, slider value to its own view
		var sliderValue: Double {
			get {
				if let guess {
					return Double(guess)
				} else {
					return Double((range.upperBound + range.lowerBound) / 2)
				}
			}
			set {
				self.guess = Int(newValue)
			}
		}
		var sliderRange: ClosedRange<Double> {
			Double(self.range.lowerBound)...Double(self.range.upperBound)
		}
		public init() {}
	}

	public enum Action: Equatable {
		case startGame
		case onDisappear
		case timerTicked
		case submitTapped
		case alertDismissed
		case sliderValueChanged(Double)
		case gamePhotosResponse(TaskResult<State.GamePhotos>)
	}

	private enum TimerID {}
	@Dependency(\.continuousClock) var clock
	@Dependency(\.apiClient) var apiClient

	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
			switch action {
			case .submitTapped:
				guard let guess = state.guess, let photoInPlay = state.currentInGamePhoto else { return .none }

				defer {
					if var gamePhotos = state.gamePhotos?.result.photos,
						 let rid = state.gamePhotos?.rid,
						 !gamePhotos.isEmpty {

						if let index = gamePhotos.indices.randomElement() {
							let value = gamePhotos.remove(at: index)
							state.currentInGamePhoto = value
							state.gamePhotos = NearestPhotosResponse(result: .init(photos: gamePhotos), rid: rid)
							state.timerSecondsElapsed = 0
							state.isTimerActive = false
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
						state.alert = AlertState { TextState("You nailed it! \(50) points!" ) }
					default:
						let distance = abs(targetYear - guess)
						let score = max(0, 50 - distance * 2)

						state.score += score
						state.alert = AlertState { TextState("Photo was taken in \(targetYear) which is \(distance) away.\n You received \(score) points") }
					}

				case let .range(lowerBound: lowerBound, upperBound: upperBound):
					let targetRange = lowerBound...upperBound
					let isContained = targetRange ~= guess

					if isContained {
						state.score += 40
						state.alert = AlertState { TextState("Your guess is within the range! \(40) points!" ) }
					} else {
						let targetYear = (lowerBound + upperBound) / 2
						let distance = abs(targetYear - guess)
						let score = max(0, 40 - distance * 2)

						state.score += score
						state.alert = AlertState { TextState("Photo was taken between \(lowerBound) and \(upperBound) \n You received \(score) points") }
					}
				}
				return .none
			case .startGame:
				state.score = 0
				state.gamePhotos = nil
				state.currentInGamePhoto = nil
				state.guess = nil

				let req = NearestPhotoRequest()
				return .task { [req] in
					await .gamePhotosResponse(
						TaskResult { try await self.apiClient.giveNearestPhotos(req) }
					)
				}
			case .onDisappear:
				return .cancel(id: TimerID.self)
			case .timerTicked:
				state.timerSecondsElapsed += 1
				if state.timerSecondsElapsed.isMultiple(of: 5) {
					state.showSubmitGuide.toggle()
				}
				return .none
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
			case let .sliderValueChanged(value):
				state.sliderValue = value
				state.isTimerActive = true
				state.timerSecondsElapsed = 0
				return .run { [isTimerActive = state.isTimerActive] send in
					guard isTimerActive else { return }
					for await _ in self.clock.timer(interval: .seconds(1)) {
						await send(.timerTicked, animation: .default)
					}
				}
				.cancellable(id: TimerID.self, cancelInFlight: true)
			case .alertDismissed:
				state.alert = nil
				return .none
			}
		}
	}
}
