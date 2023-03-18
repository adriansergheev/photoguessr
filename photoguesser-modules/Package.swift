// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "photoguesser-modules",
	platforms: [
		.iOS(.v16),
		.macOS(.v13)
	],
	products: [
		.library(name: "ApiClient", targets: ["ApiClient"]),
		.library(name: "ApiClientLive", targets: ["ApiClientLive"]),
		.library(name: "BottomMenu", targets: ["BottomMenu"]),
		.library(name: "CitiesFeature", targets: ["CitiesFeature"]),
		.library(name: "GameFeature", targets: ["GameFeature"]),
		.library(name: "GameNotification", targets: ["GameNotification"]),
		.library(name: "GameOver", targets: ["GameOver"]),
		.library(name: "Haptics", targets: ["Haptics"]),
		.library(name: "HomeFeature", targets: ["HomeFeature"]),
		.library(name: "MenuBackground", targets: ["MenuBackground"]),
		.library(name: "SharedModels", targets: ["SharedModels"]),
		.library(name: "Styleguide", targets: ["Styleguide"]),
		.library(name: "UserDefaultsClient", targets: ["UserDefaultsClient"])
	],
	dependencies: [
		.package(url: "https://github.com/pointfreeco/swift-composable-architecture", branch: "prerelease/1.0"),
		.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.1.4"),
		.package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.8.2"),
		.package(url: "https://github.com/kean/Nuke", from: "12.0.0"),
		.package(url: "https://github.com/spacenation/swiftui-sliders", .upToNextMajor(from: "2.1.0"))
	],
	targets: [
		.target(
			name: "ApiClient",
			dependencies: [
				"SharedModels",
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
			]
		),
		.target(
			name: "ApiClientLive",
			dependencies: [
				"ApiClient",
				"SharedModels",
				.product(name: "Dependencies", package: "swift-dependencies")
			]
		),
		.target(
			name: "BottomMenu",
			dependencies: [
				"Styleguide",
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "CitiesFeature",
			dependencies: [
				"ApiClientLive",
				"SharedModels",
				"Styleguide",
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
				.product(name: "NukeUI", package: "Nuke")
			]
		),
		.target(
			name: "Haptics",
			dependencies: [
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
			]
		),
		.target(
			name: "GameFeature",
			dependencies: [
				"ApiClient",
				"ApiClientLive",
				"BottomMenu",
				"GameNotification",
				"GameOver",
				"Haptics",
				"SharedModels",
				"UserDefaultsClient",
				.product(name: "Sliders", package: "swiftui-sliders"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
				.product(name: "NukeUI", package: "Nuke")
			]
		),
		.testTarget(
			name: "GameFeatureTests",
			dependencies: ["GameFeature"]
		),
		.target(
			name: "GameNotification",
			dependencies: [
				"Styleguide",
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "GameOver",
			dependencies: [
				"Styleguide",
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "HomeFeature",
			dependencies: [
				"CitiesFeature",
				"GameFeature",
				"MenuBackground"
			]
		),
		.target(
			name: "MenuBackground",
			dependencies: [
				"ApiClient",
				"ApiClientLive",
				"Styleguide",
				.product(name: "NukeUI", package: "Nuke"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			],
			resources: [.process("Resources/")]
		),
		.target(
			name: "SharedModels"
		),
		.target(
			name: "Styleguide"
		),
		.target(
			name: "UserDefaultsClient",
			dependencies: [
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
			]
		)
	]
)
