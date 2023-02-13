// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "photoguesser-modules",
	platforms: [
		.iOS(.v15),
		.macOS(.v12),
	],
	products: [
		.library(
			name: "GameFeature",
			targets: ["GameFeature"]
		),
	],
	dependencies: [
		
	],
	targets: [
		.target(
			name: "GameFeature",
			dependencies: [],
			resources: [.process("Resources/")]
		),
		.testTarget(
			name: "GameFeatureTests",
			dependencies: ["GameFeature"]
		),
	]
)
