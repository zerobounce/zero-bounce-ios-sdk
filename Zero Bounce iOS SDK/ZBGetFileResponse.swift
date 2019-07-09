//
//  ZBGetFileResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by Mount Software on 09/07/2019.
//  Copyright © 2019 Mount Software. All rights reserved.
//

import Foundation

public struct ZBGetFileResponse : Codable {
    let localFilePath: String?
    
    init(localFilePath: String?) {
        self.localFilePath = localFilePath
    }
}
