//
//  ZBCreditsResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBCreditsResponse : Codable {
    public let credits: String
    
    enum CodingKeys : String, CodingKey {
        case credits = "Credits"
    }
}

extension ZBCreditsResponse {
    /// E7: `Credits` is a JSON string holding an integer ("-1" for a dead
    /// key, "12345"). Missing, null, another JSON type, or text that is not an
    /// integer ("abc", "5.0", " 5") fails the decode, so the call reports an
    /// error with the HTTP status instead of a credit count nobody can read.
    /// Declared in an extension so the memberwise initializer is kept.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let text = try container.decode(String.self, forKey: .credits)
        let digits = text.hasPrefix("-") ? text.dropFirst() : Substring(text)
        guard !digits.isEmpty, digits.allSatisfy({ ("0"..."9").contains($0) }), Int32(text) != nil else {
            throw DecodingError.dataCorruptedError(
                forKey: .credits, in: container,
                debugDescription: "Credits is not an integer in a JSON string")
        }
        credits = text
    }
}
