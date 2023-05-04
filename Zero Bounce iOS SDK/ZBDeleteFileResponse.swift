//
//  ZBDeleteFileResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBDeleteFileResponse: Codable, Equatable {
    
    let success: Bool?
    let message: String?
    let fileName: String
    let fileId: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case fileName = "file_name"
        case fileId = "file_id"
    }
}
