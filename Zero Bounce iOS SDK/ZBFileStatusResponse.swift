//
//  ZBFileStatusResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBFileStatusResponse : Codable {
    let fileStatus: String?
    
    enum CodingKeys : String, CodingKey {
        case fileStatus = "file_status"
    }
}
