//
//  ZBValidateResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBValidateResponse : Codable, Equatable {
    ///The email address you are validating.
    public let address: String

    ///[valid, invalid, catch-all, unknown, spamtrap, abuse, do_not_mail]
    public let status: ZBValidateStatus

    ///[antispam_system, greylisted, mail_server_temporary_error, forcible_disconnect, mail_server_did_not_respond, timeout_exceeded, failed_smtp_connection, mailbox_quota_exceeded, exception_occurred, possible_traps, role_based, global_suppression, mailbox_not_found, no_dns_entries, failed_syntax_check, possible_typo, unroutable_ip_address, leading_period_removed, does_not_accept_mail, alias_address, role_based_catch_all, disposable, toxic, accept_all]
    public let subStatus: ZBValidateSubStatus?

    ///The portion of the email address before the "@" symbol.
    public let account: String?

    ///The portion of the email address after the "@" symbol.
    public let domain: String?

    ///Suggestive Fix for an email typo
    public let didYouMean: String?

    ///Age of the email domain in days or [null].
    public let domainAgeDays: String?

    ///[true/false] If the email comes from a free provider.
    public let freeEmail: Bool = false

    ///[true/false] Does the domain have an MX record.
    public let mxFound: Bool = false

    ///The preferred MX record of the domain
    public let mxRecord: String?

    ///The SMTP Provider of the email or [null] [BETA].
    public let smtpProvider: String?

    ///The first name of the owner of the email when available or [null].
    public let firstName: String?

    ///The last name of the owner of the email when available or [null].
    public let lastName: String?

    ///The gender of the owner of the email when available or [null].
    public let gender: String?

    ///The city of the IP passed in.
    public let city: String?

    ///The region/state of the IP passed in.
    public let region: String?

    ///The zipcode of the IP passed in.
    public let zipCode: String?

    ///The country of the IP passed in.
    public let country: String?

    ///The UTC time the email was validated.
    public let processedAt: String

    enum CodingKeys: String, CodingKey {
        case address
        case status
        case subStatus = "sub_status"
        case account
        case domain
        case didYouMean = "did_you_mean"
        case domainAgeDays = "domain_age_days"
        case freeEmail = "free_email"
        case mxFound = "mx_found"
        case mxRecord = "mx_record"
        case smtpProvider = "smtp_provider"
        case firstName = "firstname"
        case lastName = "lastname"
        case gender
        case city
        case region
        case zipCode = "zipcode"
        case country
        case processedAt = "processed_at"
    }
}
