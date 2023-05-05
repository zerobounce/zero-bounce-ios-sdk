//
//  ZBValidateSubStatus.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation

public enum ZBValidateSubStatus: String, Codable {
    case none = ""
    case antiSpamSystem = "antispam_system"
    case greyListed = "greylisted"
    case mailServerTemporaryError = "mail_server_temporary_error"
    case forcibleDisconnect = "forcible_disconnect"
    case mailServerDidNotRespond = "mail_server_did_not_respond"
    case timeoutExceeded = "timeout_exceeded"
    case failedSmtpConnection = "failed_smtp_connection"
    case mailboxQuotaExceeded = "mailbox_quota_exceeded"
    case exceptionOccurred = "exception_occurred"
    case possible_traps = "possible_traps"
    case roleBased = "role_based"
    case globalSuppression = "global_suppression"
    case mailbox_not_found = "mailbox_not_found"
    case noDnsEntries = "no_dns_entries"
    case failedSyntaxCheck = "failed_syntax_check"
    case possibleTypo = "possible_typo" 
    case unRoutableIpAddress = "unroutable_ip_address"
    case leadingPeriodRemoved = "leading_period_removed"
    case doesNotAcceptMail = "does_not_accept_mail"
    case aliasAddress = "alias_address"
    case roleBasedCatchAll = "role_based_catch_all"
    case disposable = "disposable"
    case toxic = "toxic"
    case alternate = "alternate"
}
