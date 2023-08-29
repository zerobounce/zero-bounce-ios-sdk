//
//  ZBValidateStatus.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public enum ZBValidateStatus: String, Codable {
    case none = ""
    case valid
    case invalid
    case catchAll = "catch-all"
    case unknown
    case spamTrap = "spamtrap"
    case abuse
    case doNotMail = "do_not_mail"
}
