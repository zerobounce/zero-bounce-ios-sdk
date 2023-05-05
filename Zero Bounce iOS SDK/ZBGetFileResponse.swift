//
//  ZBGetFileResponse.swift
//   Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBGetFileResponse : Codable {
    public let localFilePath: String?
    
    init(localFilePath: String?) {
        self.localFilePath = localFilePath
    }
}
