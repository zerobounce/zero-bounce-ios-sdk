//
//  ZBFileStatusResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBFileStatusResponse : Codable, Equatable {
    public let success: Bool
    public let fileId: String
    public let fileName: String?
    public let uploadDate: String?
    public let fileStatus: String
    public let completePercentage: String?
    public let returnUrl: String?
    
    enum CodingKeys : String, CodingKey {
        case success
        case fileId = "file_id"
        case fileName = "file_name"
        case uploadDate = "upload_date"
        case fileStatus = "file_status"
        case completePercentage = "complete_percentage"
        case returnUrl = "return_url"
    }
}
