//
//  ZBSendFileResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBSendFileResponse: Codable, Equatable {
    public let success: Bool?
    public let message: String?
    public let fileName: String
    public let fileId: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case fileName = "file_name"
        case fileId = "file_id"
    }
}
