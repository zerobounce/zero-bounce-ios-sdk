//
//  ZBGetApiUsageResponse.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public struct ZBGetApiUsageResponse : Codable, Equatable {
    /// Total number of times the API has been called
    public let total: Int
    
    /// Total valid email addresses returned by the API
    public let statusValid: Int
    
    /// Total invalid email addresses returned by the API
    public let statusInvalid: Int
    
    /// Total catch-all email addresses returned by the API
    public let statusCatchAll: Int
    
    /// Total do not mail email addresses returned by the API
    public let statusDoNotMail: Int
    
    /// Total spamtrap email addresses returned by the API
    public let statusSpamtrap: Int
    
    /// Total unknown email addresses returned by the API
    public let statusUnknown: Int
    
    /// Total number of times the API has a sub status of "toxic"
    public let subStatusToxic: Int
    
    /// Total number of times the API has a sub status of "disposable"
    public let subStatusDisposable: Int
    
    /// Total number of times the API has a sub status of "role_based"
    public let subStatusRoleBased: Int
    
    /// Total number of times the API has a sub status of "possible_trap"
    public let subStatusPossibleTrap: Int
    
    /// Total number of times the API has a sub status of "global_suppression"
    public let subStatusGlobalSuppression: Int
    
    /// Total number of times the API has a sub status of "timeout_exceeded"
    public let subStatusTimeoutExceeded: Int
    
    /// Total number of times the API has a sub status of "mail_server_temporary_error"
    public let subStatusMailServerTemporaryError: Int
    
    /// Total number of times the API has a sub status of "mail_server_did_not_respond"
    public let subStatusMailServerDidNotResponse: Int
    
    /// Total number of times the API has a sub status of "greylisted"
    public let subStatusGreyListed: Int
    
    /// Total number of times the API has a sub status of "antispam_system"
    public let subStatusAntiSpamSystem: Int
    
    /// Total number of times the API has a sub status of "does_not_accept_mail"
    public let subStatusDoesNotAcceptMail: Int
    
    /// Total number of times the API has a sub status of "exception_occurred"
    public let subStatusExceptionOccurred: Int
    
    /// Total number of times the API has a sub status of "failed_syntax_check"
    public let subStatusFailedSyntaxCheck: Int
    
    /// Total number of times the API has a sub status of "mailbox_not_found"
    public let subStatusMailboxNotFound: Int
    
    /// Total number of times the API has a sub status of "unroutable_ip_address"
    public let subStatusUnRoutableIpAddress: Int
    
    /// Total number of times the API has a sub status of "possible_typo"
    public let subStatusPossibleTypo: Int
    
    /// Total number of times the API has a sub status of "no_dns_entries"
    public let subStatusNoDnsEntries: Int
    
    /// Total role based catch alls the API has a sub status of "role_based_catch_all"
    public let subStatusRoleBasedCatchAll: Int
    
    /// Total number of times the API has a sub status of "mailbox_quota_exceeded"
    public let subStatusMailboxQuotaExceeded: Int
    
    /// Total forcible disconnects the API has a sub status of "forcible_disconnect"
    public let subStatusForcibleDisconnect: Int
    
    /// Total failed SMTP connections the API has a sub status of "failed_smtp_connection"
    public let subStatusFailedSmtpConnection: Int
    
    /// Total number of times the API has a sub status of "accept_all"
    public let subStatusAcceptAll: Int
    
    /// Total number of times the API has a sub status of "mx_forward"
    public let subStatusMxForward: Int
    
    /// Total number of times the API has a sub status of "alternate"
    public let subStatusAlternate: Int
    
    /// Total number of times the API has a sub status of "allowed"
    public let subStatusAllowed: Int
    
    /// Total number of times the API has a sub status of "blocked"
    public let subStatusBlocked: Int
    
    /// Total number of times the API has a sub status of "gold"
    public let subStatusGold: Int
    
    /// Total number of times the API has a sub status of "role_based_accept_all"
    public let subStatusRoleBasedAcceptAll: Int

    /// Total emails with a leading period that was removed
    public let subStatusLeadingPeriodRemoved: Int
    
    /// Total alias address emails returned by the API
    public let subStatusAliasAddress: Int
    
    
    /// Start date of query
    public let startDate: String?
    
    /// End date of query
    public let endDate: String?
    
    enum CodingKeys: String, CodingKey {
        case total
        case statusValid = "status_valid"
        case statusInvalid = "status_invalid"
        case statusCatchAll = "status_catch_all"
        case statusDoNotMail = "status_do_not_mail"
        case statusSpamtrap = "status_spamtrap"
        case statusUnknown = "status_unknown"
        case subStatusToxic = "sub_status_toxic"
        case subStatusDisposable = "sub_status_disposable"
        case subStatusRoleBased = "sub_status_role_based"
        case subStatusPossibleTrap = "sub_status_possible_trap"
        case subStatusGlobalSuppression = "sub_status_global_suppression"
        case subStatusTimeoutExceeded = "sub_status_timeout_exceeded"
        case subStatusMailServerTemporaryError = "sub_status_mail_server_temporary_error"
        case subStatusMailServerDidNotResponse = "sub_status_mail_server_did_not_respond"
        case subStatusGreyListed = "sub_status_greylisted"
        case subStatusAntiSpamSystem = "sub_status_antispam_system"
        case subStatusDoesNotAcceptMail = "sub_status_does_not_accept_mail"
        case subStatusExceptionOccurred = "sub_status_exception_occurred"
        case subStatusFailedSyntaxCheck = "sub_status_failed_syntax_check"
        case subStatusMailboxNotFound = "sub_status_mailbox_not_found"
        case subStatusUnRoutableIpAddress = "sub_status_unroutable_ip_address"
        case subStatusPossibleTypo = "sub_status_possible_typo"
        case subStatusNoDnsEntries = "sub_status_no_dns_entries"
        case subStatusRoleBasedCatchAll = "sub_status_role_based_catch_all"
        case subStatusMailboxQuotaExceeded = "sub_status_mailbox_quota_exceeded"
        case subStatusForcibleDisconnect = "sub_status_forcible_disconnect"
        case subStatusFailedSmtpConnection = "sub_status_failed_smtp_connection"
        case subStatusAcceptAll = "sub_status_accept_all"
        case subStatusMxForward = "sub_status_mx_forward"
        case subStatusAlternate = "sub_status_alternate"
        case subStatusAllowed = "sub_status_allowed"
        case subStatusBlocked = "sub_status_blocked"
        case subStatusGold = "sub_status_gold"
        case subStatusRoleBasedAcceptAll = "sub_status_role_based_accept_all"
        case subStatusLeadingPeriodRemoved = "sub_status_leading_period_removed"
        case subStatusAliasAddress = "sub_status_alias_address"
        case startDate = "start_date"
        case endDate = "end_date"
    }

    /// Declaring `init(from:)` suppresses the synthesized memberwise
    /// initializer, which callers and tests construct this with.
    public init(
        total: Int,
        statusValid: Int,
        statusInvalid: Int,
        statusCatchAll: Int,
        statusDoNotMail: Int,
        statusSpamtrap: Int,
        statusUnknown: Int,
        subStatusToxic: Int,
        subStatusDisposable: Int,
        subStatusRoleBased: Int,
        subStatusPossibleTrap: Int,
        subStatusGlobalSuppression: Int,
        subStatusTimeoutExceeded: Int,
        subStatusMailServerTemporaryError: Int,
        subStatusMailServerDidNotResponse: Int,
        subStatusGreyListed: Int,
        subStatusAntiSpamSystem: Int,
        subStatusDoesNotAcceptMail: Int,
        subStatusExceptionOccurred: Int,
        subStatusFailedSyntaxCheck: Int,
        subStatusMailboxNotFound: Int,
        subStatusUnRoutableIpAddress: Int,
        subStatusPossibleTypo: Int,
        subStatusNoDnsEntries: Int,
        subStatusRoleBasedCatchAll: Int,
        subStatusMailboxQuotaExceeded: Int,
        subStatusForcibleDisconnect: Int,
        subStatusFailedSmtpConnection: Int,
        subStatusAcceptAll: Int,
        subStatusMxForward: Int,
        subStatusAlternate: Int,
        subStatusAllowed: Int,
        subStatusBlocked: Int,
        subStatusGold: Int = 0,
        subStatusRoleBasedAcceptAll: Int = 0,
        subStatusLeadingPeriodRemoved: Int = 0,
        subStatusAliasAddress: Int = 0,
        startDate: String? = nil,
        endDate: String? = nil
    ) {
        self.total = total
        self.statusValid = statusValid
        self.statusInvalid = statusInvalid
        self.statusCatchAll = statusCatchAll
        self.statusDoNotMail = statusDoNotMail
        self.statusSpamtrap = statusSpamtrap
        self.statusUnknown = statusUnknown
        self.subStatusToxic = subStatusToxic
        self.subStatusDisposable = subStatusDisposable
        self.subStatusRoleBased = subStatusRoleBased
        self.subStatusPossibleTrap = subStatusPossibleTrap
        self.subStatusGlobalSuppression = subStatusGlobalSuppression
        self.subStatusTimeoutExceeded = subStatusTimeoutExceeded
        self.subStatusMailServerTemporaryError = subStatusMailServerTemporaryError
        self.subStatusMailServerDidNotResponse = subStatusMailServerDidNotResponse
        self.subStatusGreyListed = subStatusGreyListed
        self.subStatusAntiSpamSystem = subStatusAntiSpamSystem
        self.subStatusDoesNotAcceptMail = subStatusDoesNotAcceptMail
        self.subStatusExceptionOccurred = subStatusExceptionOccurred
        self.subStatusFailedSyntaxCheck = subStatusFailedSyntaxCheck
        self.subStatusMailboxNotFound = subStatusMailboxNotFound
        self.subStatusUnRoutableIpAddress = subStatusUnRoutableIpAddress
        self.subStatusPossibleTypo = subStatusPossibleTypo
        self.subStatusNoDnsEntries = subStatusNoDnsEntries
        self.subStatusRoleBasedCatchAll = subStatusRoleBasedCatchAll
        self.subStatusMailboxQuotaExceeded = subStatusMailboxQuotaExceeded
        self.subStatusForcibleDisconnect = subStatusForcibleDisconnect
        self.subStatusFailedSmtpConnection = subStatusFailedSmtpConnection
        self.subStatusAcceptAll = subStatusAcceptAll
        self.subStatusMxForward = subStatusMxForward
        self.subStatusAlternate = subStatusAlternate
        self.subStatusAllowed = subStatusAllowed
        self.subStatusBlocked = subStatusBlocked
        self.subStatusGold = subStatusGold
        self.subStatusRoleBasedAcceptAll = subStatusRoleBasedAcceptAll
        self.subStatusLeadingPeriodRemoved = subStatusLeadingPeriodRemoved
        self.subStatusAliasAddress = subStatusAliasAddress
        self.startDate = startDate
        self.endDate = endDate
    }

    /// LIVE: the API returns only the counters that apply to the account and
    /// the date range asked for — `sub_status_gold` and
    /// `sub_status_role_based_accept_all` are absent from an ordinary
    /// response. Decoding them as required keys failed the whole call, so a
    /// missing counter reads as 0 and a counter added later is ignored rather
    /// than fatal.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decodeIfPresent(Int.self, forKey: .total) ?? 0
        statusValid = try container.decodeIfPresent(Int.self, forKey: .statusValid) ?? 0
        statusInvalid = try container.decodeIfPresent(Int.self, forKey: .statusInvalid) ?? 0
        statusCatchAll = try container.decodeIfPresent(Int.self, forKey: .statusCatchAll) ?? 0
        statusDoNotMail = try container.decodeIfPresent(Int.self, forKey: .statusDoNotMail) ?? 0
        statusSpamtrap = try container.decodeIfPresent(Int.self, forKey: .statusSpamtrap) ?? 0
        statusUnknown = try container.decodeIfPresent(Int.self, forKey: .statusUnknown) ?? 0
        subStatusToxic = try container.decodeIfPresent(Int.self, forKey: .subStatusToxic) ?? 0
        subStatusDisposable = try container.decodeIfPresent(Int.self, forKey: .subStatusDisposable) ?? 0
        subStatusRoleBased = try container.decodeIfPresent(Int.self, forKey: .subStatusRoleBased) ?? 0
        subStatusPossibleTrap = try container.decodeIfPresent(Int.self, forKey: .subStatusPossibleTrap) ?? 0
        subStatusGlobalSuppression = try container.decodeIfPresent(Int.self, forKey: .subStatusGlobalSuppression) ?? 0
        subStatusTimeoutExceeded = try container.decodeIfPresent(Int.self, forKey: .subStatusTimeoutExceeded) ?? 0
        subStatusMailServerTemporaryError = try container.decodeIfPresent(Int.self, forKey: .subStatusMailServerTemporaryError) ?? 0
        subStatusMailServerDidNotResponse = try container.decodeIfPresent(Int.self, forKey: .subStatusMailServerDidNotResponse) ?? 0
        subStatusGreyListed = try container.decodeIfPresent(Int.self, forKey: .subStatusGreyListed) ?? 0
        subStatusAntiSpamSystem = try container.decodeIfPresent(Int.self, forKey: .subStatusAntiSpamSystem) ?? 0
        subStatusDoesNotAcceptMail = try container.decodeIfPresent(Int.self, forKey: .subStatusDoesNotAcceptMail) ?? 0
        subStatusExceptionOccurred = try container.decodeIfPresent(Int.self, forKey: .subStatusExceptionOccurred) ?? 0
        subStatusFailedSyntaxCheck = try container.decodeIfPresent(Int.self, forKey: .subStatusFailedSyntaxCheck) ?? 0
        subStatusMailboxNotFound = try container.decodeIfPresent(Int.self, forKey: .subStatusMailboxNotFound) ?? 0
        subStatusUnRoutableIpAddress = try container.decodeIfPresent(Int.self, forKey: .subStatusUnRoutableIpAddress) ?? 0
        subStatusPossibleTypo = try container.decodeIfPresent(Int.self, forKey: .subStatusPossibleTypo) ?? 0
        subStatusNoDnsEntries = try container.decodeIfPresent(Int.self, forKey: .subStatusNoDnsEntries) ?? 0
        subStatusRoleBasedCatchAll = try container.decodeIfPresent(Int.self, forKey: .subStatusRoleBasedCatchAll) ?? 0
        subStatusMailboxQuotaExceeded = try container.decodeIfPresent(Int.self, forKey: .subStatusMailboxQuotaExceeded) ?? 0
        subStatusForcibleDisconnect = try container.decodeIfPresent(Int.self, forKey: .subStatusForcibleDisconnect) ?? 0
        subStatusFailedSmtpConnection = try container.decodeIfPresent(Int.self, forKey: .subStatusFailedSmtpConnection) ?? 0
        subStatusAcceptAll = try container.decodeIfPresent(Int.self, forKey: .subStatusAcceptAll) ?? 0
        subStatusMxForward = try container.decodeIfPresent(Int.self, forKey: .subStatusMxForward) ?? 0
        subStatusAlternate = try container.decodeIfPresent(Int.self, forKey: .subStatusAlternate) ?? 0
        subStatusAllowed = try container.decodeIfPresent(Int.self, forKey: .subStatusAllowed) ?? 0
        subStatusBlocked = try container.decodeIfPresent(Int.self, forKey: .subStatusBlocked) ?? 0
        subStatusGold = try container.decodeIfPresent(Int.self, forKey: .subStatusGold) ?? 0
        subStatusRoleBasedAcceptAll = try container.decodeIfPresent(Int.self, forKey: .subStatusRoleBasedAcceptAll) ?? 0
        subStatusLeadingPeriodRemoved = try container.decodeIfPresent(Int.self, forKey: .subStatusLeadingPeriodRemoved) ?? 0
        subStatusAliasAddress = try container.decodeIfPresent(Int.self, forKey: .subStatusAliasAddress) ?? 0
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
    }

}
