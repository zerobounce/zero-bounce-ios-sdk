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
