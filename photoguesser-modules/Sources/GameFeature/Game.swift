import SharedModels
import ComposableArchitecture

public struct Game: ReducerProtocol {
	public struct State: Equatable {
		public typealias GamePhotos = NearestPhotosResponse
		
//		var guess: Int?
		var score: Int = 0
		var sliderValue: Double = 0
		var gamePhotos: GamePhotos?
		var currentGamePhoto: Photo?
		var range: ClosedRange<Double> = 1800...2000
		
		var alert: AlertState<Action>?
		
		public init() {}
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

				if let targetYear = state.currentGamePhoto?.year {
					
					let guess = Int(state.sliderValue)
					switch guess {
					case targetYear:
						state.alert = AlertState { TextState ("You nailed it!" )}
						state.score += 10
						state.currentGamePhoto = state.gamePhotos?.result.photos.randomElement()!
						state.sliderValue = 0
					case guess where guess > targetYear:
						state.alert = AlertState { TextState ( "Try Lower!" )}
					case guess where guess < targetYear:
						state.alert = AlertState { TextState ( "Try higher!" )}
					default: break
					}					
				}
				

//				if let guess = Int(state.sliderValue) {
//				let guess = Int(state.sliderValue)
//					switch guess {
//					case let guess where state.:
//						state.alert = AlertState { TextState ("You nailed it!" )}
//						state.score += 10
//						state.currentGamePhoto = state.gamePhotos?.result.photos.randomElement()!
//						state.sliderValue = 0
////					case let guess where guess > Int(state.range.upperBound):
////						state.alert = AlertState { TextState ( "Try Lower!" )}
////					case let guess where guess 	< Int(state.range.upperBound):
////						state.alert = AlertState { TextState ( "Try higher!" )}
//					default: break
//					}
//				}
				return .none
			case .startGame:
				
//				state.guess = nil
				state.score = 0
				state.gamePhotos = nil
				state.currentGamePhoto = nil
				
				let req = NearestPhotoRequest()
				return .task { [req] in
					await .gamePhotosResponse(
						TaskResult { try await self.apiClient.giveNearestPhotos(req) }
					)
				}
			case let .gamePhotosResponse(.success(gamePhotos)):
				state.gamePhotos = gamePhotos
				let randomElement = gamePhotos.result.photos.randomElement()!
				let year = randomElement.year
				state.currentGamePhoto = randomElement
				return .none
			case .gamePhotosResponse(.failure):
				//TODO: Handle error
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
