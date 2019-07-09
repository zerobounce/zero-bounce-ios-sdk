//
//  ZBSendFileResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Mount Software on 09/07/2019.
//  Copyright © 2019 Mount Software. All rights reserved.
//

import Foundation

public struct ZBSendFileResponse: Codable {
    
    let success: Bool?
    let message: String?
    let fileName: String?
    let fileId: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case fileName = "file_name"
        case fileId = "file_id"
    }
}
