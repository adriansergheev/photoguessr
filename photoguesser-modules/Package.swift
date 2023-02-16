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
		.library(name: "GameFeature", targets: ["GameFeature"]),
		.library(name: "GameNotification", targets: ["GameNotification"]),
		.library(name: "SharedModels", targets: ["SharedModels"]),
		.library(name: "Styleguide", targets: ["Styleguide"])
	],
	dependencies: [
		.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.50.2"),
		.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.1.4"),
		.package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.8.2"),
		.package(url: "https://github.com/kean/Nuke", .upToNextMajor(from: "11.6.2")),
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
			name: "GameFeature",
			dependencies: [
				"ApiClient",
				"ApiClientLive",
				"GameNotification",
				"SharedModels",
				.product(name: "Sliders", package: "swiftui-sliders"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
				.product(name: "NukeUI", package: "Nuke")
			],
			resources: [.process("Resources/")]
		),
		.target(
			name: "GameNotification",
			dependencies: [
				"Styleguide",
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.testTarget(
			name: "GameFeatureTests",
			dependencies: ["GameFeature"]
		),
		.target(
			name: "SharedModels"
		),
		.target(
			name: "Styleguide"
		)
	]
)
