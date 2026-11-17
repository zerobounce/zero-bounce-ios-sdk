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

    /// Decodes leniently, in any case: a status this SDK does not recognise
    /// is `.unknown` instead of failing the whole response.
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = ZBValidateStatus(rawValue: raw)
            ?? ZBValidateStatus(rawValue: raw.lowercased())
            ?? .unknown
    }
}
