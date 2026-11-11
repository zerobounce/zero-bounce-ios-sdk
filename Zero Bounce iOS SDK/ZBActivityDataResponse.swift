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
