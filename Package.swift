// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Suite",
     platforms: [
              .macOS(.v10_15),
              .iOS(.v13),
              .watchOS(.v6),
         ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Suite",
            targets: ["Suite"]),
    ],
	 dependencies: [
		  .package(url: "https://github.com/apple/swift-syntax", from: "509.0.0")
	 ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "Studio", dependencies: []),
        .target(name: "Suite", dependencies: ["Studio", "SuiteMacrosImpl"]),
		  .testTarget(name: "SuiteTests", dependencies: ["Suite", "SuiteMacrosImpl", .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")]),

			.macro(
				 name: "SuiteMacrosImpl",
				 dependencies: [
					  .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
					  .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
				 ]
			),
        
    ]
)
