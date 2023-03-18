import Haptics
import GameOver
import Foundation
import BottomMenu
import SharedModels
import GameNotification
import UserDefaultsClient
import ComposableArchitecture

public struct Game: ReducerProtocol {
	public struct State: Equatable {
		public enum GameMode: Equatable {
			case limited(max: Int, current: Int)
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
	}

	@Dependency(\.apiClient) var apiClient
	@Dependency(\.userDefaults) var userDefaults

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
					let seenKey = userDefaults.integerForKey(seenKey)
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
					var array = gamePhotos.result.photos
					if let index = array.indices.randomElement() {
						let value = array.remove(at: index)
						state.currentInGamePhoto = value
					}
					state.gameLocation.gamePhotos = PastvuPhotoResponse(result: .init(photos: array), rid: gamePhotos.rid)
					return .none
				case .gamePhotosResponse(.failure):
					return .none
				case .toggleSlider:
					state.slider = state.slider == nil ? CustomSlider.State(sliderValue: 1913, range: 1826...2000) : nil
					return .none
				case .slider(.submitTapped):
					guard let guess = state.guess, let photoInPlay = state.currentInGamePhoto else { return .none }
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
							state.gameOver = .init(score: state.score, reason: .outOfPics)
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
							state.gameNotification = .init(text: "Photo was taken in \(targetYear) which is \(distance) years away. \(score) points!")
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
							state.gameNotification = .init(text: "Photo was taken between \(lowerBound) and \(upperBound)\n\(score) points!")
						}
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
					return .none
				case .gameOver:
					return .none
				case .dismissBottomMenu:
					state.bottomMenu = nil
					return .none
				case .endGame:
					state.gameOver = .init(score: state.score)
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
		await userDefaults.setInteger(id, seenKey)
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

import SwiftUI
extension BottomMenuState where Action == Game.Action {
	public static func endGameMenu(state: Game.State) -> Self {
		var menu = BottomMenuState(
			title: .init("Solo"),
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
