//
//  ZBEmailConfidence.swift
//  Zero Bounce iOS SDK
//
//  Created by Robert Manea on 03.10.2025.
//  Copyright © 2025 ZeroBounce. All rights reserved.
//

import Foundation

public enum ZBEmailConfidence: String, Codable {
    case none = ""
    case low
    case medium
    case high
    /// LIVE: what the finder answers when it could not resolve an address.
    case undetermined
    /// A value this SDK does not know. Decoding it no longer fails the response.
    case unknown

    /// Matches case-insensitively (the docs write HIGH, MEDIUM, LOW; the API
    /// sends lowercase), and maps a value this SDK does not know to `.unknown`
    /// instead of failing the whole response.
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ZBEmailConfidence(rawValue: raw.trimmingCharacters(in: .whitespaces).lowercased()) ?? .unknown
    }
}
