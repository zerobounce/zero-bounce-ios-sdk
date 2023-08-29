//
//  ZBConfidence.swift
//  Zero Bounce iOS SDK
//
//  Created by Andreea Sinescu on 23.08.2023.
//  Copyright © 2023 Mount Software. All rights reserved.
//

import Foundation

public enum ZBConfidence: String, Codable {
    case none = ""
    case low
    case medium
    case high
    case unknown
    case undetermined
}
