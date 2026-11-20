//
//  ZeroBounceSDKProtocol.swift
//  Zero Bounce iOS SDK
//
//  The public API of `ZeroBounceSDK` as a protocol, so app code can hold
//  `any ZeroBounceSDKProtocol` and a test can hand it a fake.
//

import Foundation

/// Every public API method of `ZeroBounceSDK` (validation, scoring, finders,
/// bulk files, list evaluator, filters, S3/SFTP and the Inbox Placement
/// Tester), with the same signatures, so code under test can take a fake in
/// place of the client:
///
/// ```swift
/// final class Signup {
///     let client: any ZeroBounceSDKProtocol
///     init(client: any ZeroBounceSDKProtocol = ZeroBounceSDK.shared) { self.client = client }
/// }
/// ```
///
/// Setup is left out: `initialize(apiKey:apiBaseUrl:)`,
/// `setListEvaluatorBaseUrl(_:)`, `setInboxPlacementBaseUrl(_:)` and the static
/// `shared` and `setSessionConfiguration(_:)`. Configure the real client before
/// handing it over.
///
/// The protocol gains a requirement with every method the client gains, in
/// minor releases. It is meant for test fakes and type annotations, not as a
/// stable contract for your own conforming types: a fake may have to add
/// methods when you upgrade.
///
/// Swift protocols cannot declare default arguments, so each requirement takes
/// every argument. The extension below adds, for each method with defaults, the
/// overload that leaves all of them out; to pass some but not all of them
/// through the protocol, pass the rest explicitly (`nil` for an optional).
public protocol ZeroBounceSDKProtocol {
    /// - parameter email: The email address you want to validate
    /// - parameter ipAddress: The IP Address the email signed up from (Can be blank)
    func validate(
        email: String,
        ipAddress: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBValidateResponse>) -> ()
    )

    func validate(
        email: String,
        ipAddress: String?,
        options: ZBValidateOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBValidateResponse>) -> ()
    )

    /// - parameter emails: List of email addresses you want to validate
    func validateBatch(
        emails: [[String:String]],
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBValidateBatchResponse>) -> ()
    )

    func validateBatch(
        emails: [[String:String]],
        options: ZBValidateOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBValidateBatchResponse>) -> ()
    )

    /// - parameter domain: The email domain for which to find the email format
    /// - parameter firstName: The first name of the person whose email format is being searched. Optional: a search by middle or last name alone is allowed, but at least one of the three names is needed.
    /// - parameter middleName: The middle name of the person whose email format is being searched
    /// - parameter lastName: The last name of the person whose email format is being searched
    func findEmail(
        domain: String,
        firstName: String?,
        middleName: String?,
        lastName: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBEmailFinderResponse>) -> ()
    )

    /// - parameter companyName: The company name for which to find the email format
    /// - parameter firstName: The first name of the person whose email format is being searched. Optional, as on the domain overload.
    /// - parameter middleName: The middle name of the person whose email format is being searched
    /// - parameter lastName: The last name of the person whose email format is being searched
    func findEmail(
        companyName: String,
        firstName: String?,
        middleName: String?,
        lastName: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBEmailFinderResponse>) -> ()
    )

    /// - parameter domain: The email domain for which to find the email format
    func findDomain(
        domain: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBDomainSearchResponse>) -> ()
    )

    /// - parameter companyName: The company name for which to find the email format
    func findDomain(
        companyName: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBDomainSearchResponse>) -> ()
    )

    @available(*, deprecated, message: "Use findEmail() for Email Finder API, or findDomain() for Domain Search API")
    func guessFormat(
        domain: String,
        firstName: String?,
        middleName: String?,
        lastName: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBEmailFinderResponse>) -> ()
    )

    /// This API will tell you how many credits you have left on your account. It's simple, fast and easy to use.
    func getCredits(completion: @escaping (ZeroBounceSDK.ZBResult<ZBCreditsResponse>) -> ())

    /// - parameter startDate: The start date of when you want to view API usage
    /// - parameter endDate: The end date of when you want to view API usage
    func getApiUsage(
        startDate: Date,
        endDate: Date,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetApiUsageResponse>) -> ()
    )

    /// - parameter email: The email inbox you want to check the activity data for
    func getActivityData(email: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBActivityDataResponse>) -> ())

    /// Real-time AI scoring for a single email (GET /scoring).
    func scoreEmail(email: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBScoreEmailResponse>) -> ())

    /// Real-time AI scoring for a single email (POST /scoring, form-encoded).
    func scoreEmailPost(email: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBScoreEmailResponse>) -> ())

    func sendEmailFinderFile(
        filePath: String,
        domainColumn: Int,
        options: ZBEmailFinderSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func sendEmailFinderFileData(
        fileData: Data,
        fileName: String,
        domainColumn: Int,
        options: ZBEmailFinderSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func emailFinderFileStatus(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBFileStatusResponse>) -> ())

    func emailFinderGetFile(
        fileId: String,
        downloadPath: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    )

    func emailFinderDeleteFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBDeleteFileResponse>) -> ())

    func sendDomainSearchFile(
        filePath: String,
        domainColumn: Int,
        options: ZBDomainSearchSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func sendDomainSearchFileData(
        fileData: Data,
        fileName: String,
        domainColumn: Int,
        options: ZBDomainSearchSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func domainSearchFileStatus(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBFileStatusResponse>) -> ())

    func domainSearchGetFile(
        fileId: String,
        downloadPath: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    )

    func domainSearchDeleteFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBDeleteFileResponse>) -> ())

    func sendListEvaluatorFile(
        filePath: String,
        emailAddressColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func sendListEvaluatorFileData(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func getListEvaluatorResult(fileId: String, completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ())

    /// Submits a list the list evaluator has finished for bulk validation.
    ///
    /// Takes the id of a finished evaluation, not a path to upload: that is
    /// what the live endpoint wants.
    func sendEvaluatedFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ())

    func addFilter(
        rule: String,
        target: String,
        value: String,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    )

    /// Lists the account's filters.
    ///
    /// The body is a JSON array, so this hands back `ZBJsonResult`: cast the
    /// success value to `[[String: Any]]`.
    func listFilters(usePost: Bool, completion: @escaping (ZeroBounceSDK.ZBJsonResult) -> ())

    func deleteFilter(
        rule: String,
        target: String,
        value: String,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    )

    func validateS3File(
        options: ZBValidateS3FileOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func scoreS3File(
        options: ZBScoreS3FileOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    /// `export_bucket` is optional: pass nil to use the export bucket from
    /// your ZeroBounce settings.
    func exportS3File(
        fileId: String,
        exportBucket: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func emailFinderS3File(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func domainSearchS3File(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    /// `options.fileName` and `options.returnUrl` are both required, and a
    /// missing or blank one is rejected before a request is sent. The docs list
    /// this job's file_name as optional, but the live API rejects the call
    /// without it ("Empty parameter: file_name").
    func validateSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func scoreSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func emailFinderSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func domainSearchSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    /// Note the field name: this endpoint takes export_path, not the
    /// export_bucket that `exportS3File` sends. Pass nil to use the export path
    /// from your ZeroBounce settings.
    func exportSFTPFile(
        fileId: String,
        exportPath: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    func getInboxPlacementProviders(completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ())

    func getInboxPlacementTestTypes(completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ())

    func createInboxPlacementTest(
        name: String,
        options: ZBCreateInboxPlacementTestOptions?,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    )

    func getInboxPlacementTest(testId: String, completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ())

    func listInboxPlacementTests(
        options: ZBListInboxPlacementTestsOptions?,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    )

    func deleteInboxPlacementTest(testId: String, completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ())

    func getInboxPlacementWebhook(completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ())

    func setInboxPlacementWebhook(webhookUrl: String, completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ())

    func listS3files(
        bucket: String?,
        search: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<[ZBS3ListFileEntry]>) -> ()
    )

    /// - parameter fileId: The returned file ID when calling sendFile API.
    func fileStatus(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBFileStatusResponse>) -> ())

    /// - parameter fileId: The returned file ID when calling scoringSendFile API.
    func scoringFileStatus(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBFileStatusResponse>) -> ())

    /// - parameter fileId: The returned file ID when calling sendfile API.
    func deleteFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBDeleteFileResponse>) -> ())

    /// - parameter fileId: The returned file ID when calling scoringSendfile API.
    func scoringDeleteFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBDeleteFileResponse>) -> ())

    /// The sendfile API allows user to send a file for bulk email validation
    ///
    /// - parameter filePath: The path to a local file in String format
    /// - parameter emailAddressColumn: The column index of the email address in the file. Index starts from 1
    /// - parameter returnUrl: The URL will be used to call back when the validation is completed
    /// - parameter firstNameColumn: The column index of the first name column
    /// - parameter lastNameColumn: The column index of the last name column
    /// - parameter genderColumn: The column index of the gender column
    /// - parameter ipAddressColumn: The IP Address the email signed up from
    /// - parameter hasHeaderRow: If the first row from the submitted file is a header row. true or false
    /// - parameter allowPhase2: Validate catch-all emails in a second phase (Verify+). Not sent when nil
    /// - parameter removeDuplicate: Whether the API removes duplicate emails. Not sent when nil, and the API
    ///   then removes them (default true). When more than 50% of the rows are duplicates and this is true,
    ///   the API answers HTTP 400 instead of accepting the file. `scoringSendFile` takes it too.
    func sendFile(
        filePath: String,
        emailAddressColumn: Int,
        returnUrl: String?,
        firstNameColumn: Int?,
        lastNameColumn: Int?,
        genderColumn: Int?,
        ipAddressColumn: Int?,
        hasHeaderRow: Bool,
        allowPhase2: Bool?,
        removeDuplicate: Bool?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    /// Send a file for bulk email validation from in-memory data (e.g. CSV built in memory).
    func sendFile(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        returnUrl: String?,
        firstNameColumn: Int?,
        lastNameColumn: Int?,
        genderColumn: Int?,
        ipAddressColumn: Int?,
        hasHeaderRow: Bool,
        allowPhase2: Bool?,
        removeDuplicate: Bool?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    /// The scoringSendfile API allows user to send a file for bulk email validation (AI Scoring)
    func scoringSendFile(
        filePath: String,
        emailAddressColumn: Int,
        returnUrl: String?,
        hasHeaderRow: Bool,
        removeDuplicate: Bool?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    /// Send a file for bulk email scoring from in-memory data.
    func scoringSendFile(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        returnUrl: String?,
        hasHeaderRow: Bool,
        removeDuplicate: Bool?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    )

    /// The getfile API allows users to get the validation results file for the file been submitted using sendfile API
    ///
    /// - parameter fileId: The returned file ID when calling sendfile API
    func getFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ())

    /// Validation bulk `getfile` with optional `download_type` and `activity_data`.
    func getFile(
        fileId: String,
        options: ZBGetFileOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    )

    /// As `getFile`, but written straight to `downloadPath` as it arrives
    /// instead of being held in memory first — use it for a result file too
    /// large to buffer.
    ///
    /// It is opt-in because a streamed body cannot be inspected as a whole,
    /// and `getfile` answers an unknown or deleted file id with a JSON error
    /// rather than a file. The first bytes are checked before the download is
    /// moved into place, so an error still reaches the failure result and no
    /// partial file is left behind.
    func getFileStreaming(
        fileId: String,
        downloadPath: String,
        options: ZBGetFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    )

    /// The AI scoring counterpart of `getFileStreaming`.
    func scoringGetFileStreaming(
        fileId: String,
        downloadPath: String,
        options: ZBGetFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    )

    /// The scoringGetFile API allows users to get the validation results file for the file been submitted using scoringSendfile API
    func scoringGetFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ())

    /// Scoring bulk `getfile` with optional `download_type` (`activityData` is ignored).
    func scoringGetFile(
        fileId: String,
        options: ZBGetFileOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    )
}

extension ZeroBounceSDK: ZeroBounceSDKProtocol {}

// `public extension` rather than `public func`: these forward to a
// requirement, they are not request methods of their own, and the source
// sweeps in the tests look for `public func`.
public extension ZeroBounceSDKProtocol {
    /// Calls the requirement with `ipAddress: nil`, the class's default arguments.
    func validate(email: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBValidateResponse>) -> ()) {
        validate(email: email, ipAddress: nil, completion: completion)
    }

    /// Calls the requirement with `ipAddress: nil`, the class's default arguments.
    func validate(
        email: String,
        options: ZBValidateOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBValidateResponse>) -> ()
    ) {
        validate(email: email, ipAddress: nil, options: options, completion: completion)
    }

    /// Calls the requirement with `firstName: nil`, `middleName: nil`, `lastName: nil`, the class's default arguments.
    func findEmail(domain: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBEmailFinderResponse>) -> ()) {
        findEmail(
            domain: domain,
            firstName: nil,
            middleName: nil,
            lastName: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `firstName: nil`, `middleName: nil`, `lastName: nil`, the class's default arguments.
    func findEmail(
        companyName: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        findEmail(
            companyName: companyName,
            firstName: nil,
            middleName: nil,
            lastName: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `firstName: nil`, `middleName: nil`, `lastName: nil`, the class's default arguments.
    @available(*, deprecated, message: "Use findEmail() for Email Finder API, or findDomain() for Domain Search API")
    func guessFormat(domain: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBEmailFinderResponse>) -> ()) {
        guessFormat(
            domain: domain,
            firstName: nil,
            middleName: nil,
            lastName: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `options: nil`, the class's default arguments.
    func sendEmailFinderFile(
        filePath: String,
        domainColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        sendEmailFinderFile(
            filePath: filePath,
            domainColumn: domainColumn,
            options: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `options: nil`, the class's default arguments.
    func sendEmailFinderFileData(
        fileData: Data,
        fileName: String,
        domainColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        sendEmailFinderFileData(
            fileData: fileData,
            fileName: fileName,
            domainColumn: domainColumn,
            options: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `options: nil`, the class's default arguments.
    func sendDomainSearchFile(
        filePath: String,
        domainColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        sendDomainSearchFile(
            filePath: filePath,
            domainColumn: domainColumn,
            options: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `options: nil`, the class's default arguments.
    func sendDomainSearchFileData(
        fileData: Data,
        fileName: String,
        domainColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        sendDomainSearchFileData(
            fileData: fileData,
            fileName: fileName,
            domainColumn: domainColumn,
            options: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `usePost: false`, the class's default arguments.
    func listFilters(completion: @escaping (ZeroBounceSDK.ZBJsonResult) -> ()) {
        listFilters(usePost: false, completion: completion)
    }

    /// Calls the requirement with `options: nil`, the class's default arguments.
    func createInboxPlacementTest(name: String, completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) {
        createInboxPlacementTest(name: name, options: nil, completion: completion)
    }

    /// Calls the requirement with `options: nil`, the class's default arguments.
    func listInboxPlacementTests(completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) {
        listInboxPlacementTests(options: nil, completion: completion)
    }

    /// Calls the requirement with `bucket: nil`, `search: nil`, the class's default arguments.
    func listS3files(completion: @escaping (ZeroBounceSDK.ZBResult<[ZBS3ListFileEntry]>) -> ()) {
        listS3files(bucket: nil, search: nil, completion: completion)
    }

    /// Calls the requirement with `returnUrl: nil`, `firstNameColumn: nil`, `lastNameColumn: nil`, `genderColumn: nil`, `ipAddressColumn: nil`, `hasHeaderRow: false`, `allowPhase2: nil`, `removeDuplicate: nil`, the class's default arguments.
    func sendFile(
        filePath: String,
        emailAddressColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        sendFile(
            filePath: filePath,
            emailAddressColumn: emailAddressColumn,
            returnUrl: nil,
            firstNameColumn: nil,
            lastNameColumn: nil,
            genderColumn: nil,
            ipAddressColumn: nil,
            hasHeaderRow: false,
            allowPhase2: nil,
            removeDuplicate: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `returnUrl: nil`, `firstNameColumn: nil`, `lastNameColumn: nil`, `genderColumn: nil`, `ipAddressColumn: nil`, `hasHeaderRow: false`, `allowPhase2: nil`, `removeDuplicate: nil`, the class's default arguments.
    func sendFile(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        sendFile(
            fileData: fileData,
            fileName: fileName,
            emailAddressColumn: emailAddressColumn,
            returnUrl: nil,
            firstNameColumn: nil,
            lastNameColumn: nil,
            genderColumn: nil,
            ipAddressColumn: nil,
            hasHeaderRow: false,
            allowPhase2: nil,
            removeDuplicate: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `returnUrl: nil`, `hasHeaderRow: false`, `removeDuplicate: nil`, the class's default arguments.
    func scoringSendFile(
        filePath: String,
        emailAddressColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        scoringSendFile(
            filePath: filePath,
            emailAddressColumn: emailAddressColumn,
            returnUrl: nil,
            hasHeaderRow: false,
            removeDuplicate: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `returnUrl: nil`, `hasHeaderRow: false`, `removeDuplicate: nil`, the class's default arguments.
    func scoringSendFile(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        scoringSendFile(
            fileData: fileData,
            fileName: fileName,
            emailAddressColumn: emailAddressColumn,
            returnUrl: nil,
            hasHeaderRow: false,
            removeDuplicate: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `options: nil`, the class's default arguments.
    func getFileStreaming(
        fileId: String,
        downloadPath: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    ) {
        getFileStreaming(
            fileId: fileId,
            downloadPath: downloadPath,
            options: nil,
            completion: completion
        )
    }

    /// Calls the requirement with `options: nil`, the class's default arguments.
    func scoringGetFileStreaming(
        fileId: String,
        downloadPath: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    ) {
        scoringGetFileStreaming(
            fileId: fileId,
            downloadPath: downloadPath,
            options: nil,
            completion: completion
        )
    }
}
