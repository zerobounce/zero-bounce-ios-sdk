//
//  ZBActivityDataResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Iliescu Andrei on 04.05.2023.
//  Copyright © 2023 Mount Software. All rights reserved.
//

import Foundation

public struct ZBActivityDataResponse: Codable, Equatable {
    let found: Bool
    let activeInDays: String?
    
    enum CodingKeys: String, CodingKey {
        case found
        case activeInDays = "active_in_days"
    }
}
