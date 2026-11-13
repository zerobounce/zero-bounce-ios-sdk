//
//  ZBActivityDataResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Iliescu Andrei on 04.05.2023.
//  Copyright © 2023 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBActivityDataResponse: Codable, Equatable {
    public let found: Bool
    public let activeInDays: String?
    
    enum CodingKeys: String, CodingKey {
        case found
        case activeInDays = "active_in_days"
    }
}

extension ZBActivityDataResponse {
    /// A null `found` reads as false (standard section 3). Declared in an
    /// extension so the memberwise initializer is kept.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        found = try container.decodeNullAsEmpty(Bool.self, forKey: .found, empty: false)
        activeInDays = try container.decodeIfPresent(String.self, forKey: .activeInDays)
    }
}
