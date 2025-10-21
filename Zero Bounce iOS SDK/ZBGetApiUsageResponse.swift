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
        case startDate = "start_date"
        case endDate = "end_date"
    }
}
