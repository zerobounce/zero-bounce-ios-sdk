//
//  ZBValidateResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBValidateResponse : Codable, Equatable {
    ///The email address you are validating. Empty when the API answered only
    ///a greylist `message`.
    public let address: String

    ///[valid, invalid, catch-all, unknown, spamtrap, abuse, do_not_mail]
    ///
    ///Absent while a greylist retry is still running, which answers with
    ///`message` instead of a result.
    public let status: ZBValidateStatus?

    ///[antispam_system, greylisted, ..., possible_trap, ..., mx_forward, blocked, allowed, accept_all, role_based_accept_all, gold]
    public let subStatus: ZBValidateSubStatus?

    ///The portion of the email address before the "@" symbol.
    public let account: String?

    ///The portion of the email address after the "@" symbol.
    public let domain: String?

    ///Suggestive Fix for an email typo
    public let didYouMean: String?

    ///Age of the email domain in days or [null].
    public let domainAgeDays: String?

    ///Last activity bucket when activity_data was requested.
    public let activeInDays: String?

    ///First date activity was detected (YYYY-MM-DD).
    public let activeFirstSeen: String?

    ///[true/false] If the email comes from a free provider.
    public let freeEmail: Bool

    ///[true/false] Does the domain have an MX record.
    public let mxFound: Bool

    ///The preferred MX record of the domain
    public let mxRecord: String?

    ///The SMTP Provider of the email or [null] [BETA].
    public let smtpProvider: String?

    ///[true/false or null] Is the domain name a catch-all (the domain email server responds with valid to any SMTP checks and emailing to an invalid might not bounce)?
    public let catchallDomain: Bool?

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

    ///The UTC time the email was validated. Absent while a greylist retry is
    ///still running, which answers with `message` instead of a result.
    public let processedAt: String?

    ///Returned with domain_info.
    public let domainWebsiteExists: String?

    ///Returned with domain_info.
    public let domainRegistrantCompanyName: String?

    ///The API's "Message" key, returned instead of a result while a greylist
    ///retry is still running.
    public let message: String?

    enum CodingKeys: String, CodingKey {
        case address
        case status
        case subStatus = "sub_status"
        case account
        case domain
        case didYouMean = "did_you_mean"
        case domainAgeDays = "domain_age_days"
        case activeInDays = "active_in_days"
        case activeFirstSeen = "active_first_seen"
        case freeEmail = "free_email"
        case mxFound = "mx_found"
        case mxRecord = "mx_record"
        case smtpProvider = "smtp_provider"
        case catchallDomain = "catchall_domain"
        case firstName = "firstname"
        case lastName = "lastname"
        case gender
        case city
        case region
        case zipCode = "zipcode"
        case country
        case processedAt = "processed_at"
        case domainWebsiteExists = "domain_website_exists"
        case domainRegistrantCompanyName = "domain_registrant_company_name"
        case message = "Message"
    }
}

extension ZBValidateResponse {
    /// Written out because synthesized `Decodable` skips a `let` that already
    /// has a default value: `activeInDays`, `activeFirstSeen`, `freeEmail`,
    /// `mxFound` and `catchallDomain` used to be declared `= nil` / `= false`
    /// and so were never read from the response, whatever the API sent.
    ///
    /// Those five accept two spellings: the API sends `mx_found` (and
    /// sometimes `free_email`) as the string "true" or "false" rather than a
    /// JSON boolean, so both are read, and `active_in_days` /
    /// `active_first_seen` as a string or a number. Any other value (E7: a
    /// number for a boolean, "maybe", an array or an object) fails the decode,
    /// as a wrong type does for every other field; null or a missing key
    /// leaves the default.
    ///
    /// Declared in an extension so the memberwise initializer is kept.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // LIVE: a repeated greylisted validate answers a bare
        // {"Message": "Greylist validation still in progress..."} with no
        // address. That is a result (the text is on `message`), so the address
        // is then empty. Without a Message, a result names its address and
        // status (E7: present, not null, strings); a missing or null one is an
        // error.
        let greylistAnswer = !(try container.decodeIfPresent(String.self, forKey: .message) ?? "").isEmpty
        if let address = try container.decodeIfPresent(String.self, forKey: .address) {
            self.address = address
        } else if greylistAnswer {
            self.address = ""
        } else {
            self.address = try container.decode(String.self, forKey: .address)
        }
        if greylistAnswer {
            status = try container.decodeIfPresent(ZBValidateStatus.self, forKey: .status)
        } else {
            status = try container.decode(ZBValidateStatus.self, forKey: .status)
        }
        subStatus = try container.decodeIfPresent(ZBValidateSubStatus.self, forKey: .subStatus)
        account = try container.decodeIfPresent(String.self, forKey: .account)
        domain = try container.decodeIfPresent(String.self, forKey: .domain)
        didYouMean = try container.decodeIfPresent(String.self, forKey: .didYouMean)
        domainAgeDays = try container.decodeIfPresent(String.self, forKey: .domainAgeDays)
        activeInDays = try ZBValidateResponse.lenientString(container, .activeInDays)
        activeFirstSeen = try ZBValidateResponse.lenientString(container, .activeFirstSeen)
        freeEmail = try ZBValidateResponse.lenientBool(container, .freeEmail) ?? false
        mxFound = try ZBValidateResponse.lenientBool(container, .mxFound) ?? false
        mxRecord = try container.decodeIfPresent(String.self, forKey: .mxRecord)
        smtpProvider = try container.decodeIfPresent(String.self, forKey: .smtpProvider)
        catchallDomain = try ZBValidateResponse.lenientBool(container, .catchallDomain)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        region = try container.decodeIfPresent(String.self, forKey: .region)
        zipCode = try container.decodeIfPresent(String.self, forKey: .zipCode)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        processedAt = try container.decodeIfPresent(String.self, forKey: .processedAt)
        domainWebsiteExists = try container.decodeIfPresent(String.self, forKey: .domainWebsiteExists)
        domainRegistrantCompanyName = try container.decodeIfPresent(String.self, forKey: .domainRegistrantCompanyName)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }

    /// A JSON boolean, or the string "true" / "false" in any case; nil for
    /// null or a missing key. Anything else throws.
    private static func lenientBool(
        _ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys
    ) throws -> Bool? {
        if try !container.contains(key) || container.decodeNil(forKey: key) { return nil }
        if let flag = try? container.decode(Bool.self, forKey: key) {
            return flag
        }
        if let text = try? container.decode(String.self, forKey: key) {
            switch text.trimmingCharacters(in: .whitespaces).lowercased() {
            case "true": return true
            case "false": return false
            default: break
            }
        }
        throw DecodingError.dataCorruptedError(
            forKey: key, in: container, debugDescription: "\(key.stringValue) is not a boolean")
    }

    /// A JSON string, or a whole number spelled as one; nil for null or a
    /// missing key. Anything else throws.
    private static func lenientString(
        _ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys
    ) throws -> String? {
        if try !container.contains(key) || container.decodeNil(forKey: key) { return nil }
        if let text = try? container.decode(String.self, forKey: key) {
            return text
        }
        if let number = try? container.decode(Int.self, forKey: key) {
            return String(number)
        }
        throw DecodingError.dataCorruptedError(
            forKey: key, in: container, debugDescription: "\(key.stringValue) is not a string")
    }
}
