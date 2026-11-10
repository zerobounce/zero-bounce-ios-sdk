// swift-tools-version:5.5
//
//  Package.swift
//

import PackageDescription

let package = Package(
    name: "ZeroBounceSDK",
    platforms: [.iOS(.v15), .macCatalyst(.v15)],
    products: [.library(name: "ZeroBounceSDK", targets: ["ZeroBounceSDK"])],
    targets: [
        .target(
            name: "ZeroBounceSDK",
            path: "Zero Bounce iOS SDK",
            exclude: ["Info.plist"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
