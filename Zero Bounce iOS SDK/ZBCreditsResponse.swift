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
    /// E7: `Credits` is an integer, sent as a JSON string ("-1" for a dead
    /// key, "12345") or as a JSON integer (`{"Credits":2375323}`,
    /// zerobounce.net's own example), kept here as its decimal text. Missing,
    /// null, another JSON type (a fraction, a boolean), text that is not an
    /// integer ("abc", "5.0", " 5") or a value outside Int32 fails the
    /// decode, so the call reports an error with the HTTP status instead of a
    /// credit count nobody can read. JSONDecoder reads a JSON number by value,
    /// so a whole number written `5.0` or `1e3` is read as 5 or 1000.
    /// Declared in an extension so the memberwise initializer is kept.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let number = try? container.decode(Int32.self, forKey: .credits) {
            credits = String(number)
            return
        }
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
