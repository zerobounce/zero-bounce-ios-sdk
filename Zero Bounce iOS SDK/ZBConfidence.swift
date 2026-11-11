//
//  ZBConfidence.swift
//  Zero Bounce iOS SDK
//
//  Created by Andreea Sinescu on 23.08.2023.
//  Copyright © 2023 ZeroBounce. All rights reserved.
//

import Foundation

public enum ZBConfidence: String, Codable {
    case none = ""
    case low
    case medium
    case high
    case unknown
    case undetermined

    /// Matches case-insensitively, and maps a value this SDK does not know to
    /// `.unknown` instead of failing the whole domain search response.
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ZBConfidence(rawValue: raw.trimmingCharacters(in: .whitespaces).lowercased()) ?? .unknown
    }
}
