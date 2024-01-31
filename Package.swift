// swift-tools-version:5.3
//
//  Package.swift
//

import PackageDescription

let package = Package(
    name: "ZeroBounceSDK",
    platforms: [.iOS(.v9)],
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
