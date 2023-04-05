import XCTest
@testable import GameFeature

@MainActor
final class GameFeatureTests: XCTestCase {
	func testContainsCyrillicCharacters() throws {
		let textPairs = [
			("Hello, world!", false),
			("Привет, мир!", true),
			("Hello, how are you?", false),
			("Привет, как дела?", true),
			("My name is John.", false),
			("Меня зовут Джон.", true),
			("What's the weather like today?", false),
			("Какая сегодня погода?", true),
			("I like to play soccer.", false),
			("Мне нравится играть в футбол.", true),
			("Where is the nearest supermarket?", false),
			("Где ближайший супермаркет?", true)
		]

		for (index, textPair) in textPairs.enumerated() {
			let (text, expectedResult) = textPair
			let result = containsCyrillicCharacters(text)

			XCTAssert(result == expectedResult, "Test case \(index + 1) failed: expected \(expectedResult), got \(result)")
		}
	}

	func testContainsLeakedYear() throws {
		let textPairs = [
			("I went to the park.", false),
			("I went to the park in 2020.", true),
			("She bought a new car.", false),
			("She bought a new car in 2018.", true),
			("We enjoyed the concert last night.", false),
			("We enjoyed the concert on December 12, 2019.", true),
			("The construction of the building is in progress.", false),
			("The construction of the building started in 2021.", true),
			("He learned to play the guitar.", false),
			("He learned to play the guitar in 2017.", true),
			("They visited several countries during their trip.", false),
			("They visited several countries during their trip in 2015.", true)
		]

		for (index, textPair) in textPairs.enumerated() {
			let (text, expectedResult) = textPair
			let result = containsLeakedYear(text)

			XCTAssert(result == expectedResult, "Test case \(index + 1) failed: expected \(expectedResult), got \(result)")
		}
	}
}
