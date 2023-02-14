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
		if let yearUpperBound = yearUpperBound {
			return .range(lowerBound: self.year, upperBound: yearUpperBound)
		} else {
			return .year(self.year)
		}
	}
}

public struct Game: ReducerProtocol {
	public struct State: Equatable {
		public typealias GamePhotos = NearestPhotosResponse
		
		var score: Int = 0
		var gamePhotos: GamePhotos?
		var currentInGamePhoto: Photo?
		var alert: AlertState<Action>?
		
		var guess: Int?
		fileprivate var range: ClosedRange<Int> = 1826...2000
		
		public init() {}
		
		var sliderValue: Double {
			get {
				if let guess = guess {
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
	}
	
	public enum Action: Equatable {
		case startGame
		case submitTapped
		case alertDismissed
		case sliderValueChanged(Double)
		case gamePhotosResponse(TaskResult<State.GamePhotos>)
	}
	
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
						state.alert = AlertState { TextState ("You nailed it! \(50) points!" ) }
					default:
						let distance = abs(targetYear - guess)
						let score = max(0, 50 - distance * 2)
						
						state.score += score
						state.alert = AlertState { TextState ("You were \(distance) years away from \(targetYear).\n You receive \(score) points") }
					}
					
				case let .range(lowerBound: lowerBound, upperBound: upperBound):
					fatalError()
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
				return .none
			case .alertDismissed:
				state.alert = nil
				return .none
			}
		}
	}
}
