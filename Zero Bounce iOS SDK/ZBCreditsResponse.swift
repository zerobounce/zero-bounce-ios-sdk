//
//  ZBCreditsResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Mount Software on 09/07/2019.
//  Copyright © 2019 Mount Software. All rights reserved.
//

import Foundation

public struct ZBCreditsResponse : Codable {
    
    let credits: String?
    
    enum CodingKeys : String, CodingKey {
        case credits = "Credits"
    }
}
