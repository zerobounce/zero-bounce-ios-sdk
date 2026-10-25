//
//  Priority3Api.swift
//  Zero Bounce iOS SDK
//

import Foundation

internal final class Priority3Api {

    private unowned let sdk: ZeroBounceSDK

    init(sdk: ZeroBounceSDK) {
        self.sdk = sdk
    }

    func sendEmailFinderFile(
        filePath: String,
        domainColumn: Int,
        options: ZBEmailFinderSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard checkEmailFinderColumns(domainColumn: domainColumn, options: options, completion: completion) else {
            return
        }
        let url = "\(sdk.bulkApiRootUrl)/email-finder/sendfile"
        sendBulkRootMultipart(
            url: url,
            filePath: filePath,
            fields: buildEmailFinderFields(domainColumn: domainColumn, options: options),
            completion: completion
        )
    }

    func sendEmailFinderFileData(
        fileData: Data,
        fileName: String,
        domainColumn: Int,
        options: ZBEmailFinderSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard checkEmailFinderColumns(domainColumn: domainColumn, options: options, completion: completion) else {
            return
        }
        let url = "\(sdk.bulkApiRootUrl)/email-finder/sendfile"
        sendBulkRootMultipartData(
            url: url,
            fileData: fileData,
            fileName: fileName,
            fields: buildEmailFinderFields(domainColumn: domainColumn, options: options),
            completion: completion
        )
    }

    /// The bulk email finder needs a column to read a name from: the docs make
    /// first_name_column and full_name_column alternatives, and a file with
    /// neither has nothing to search for.
    private func checkEmailFinderColumns(
        domainColumn: Int,
        options: ZBEmailFinderSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) -> Bool {
        if domainColumn < 1 {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: domain_column"])))
            return false
        }
        if (options?.firstNameColumn ?? 0) < 1 && (options?.fullNameColumn ?? 0) < 1 {
            completion(.Failure(ZBError.decodeError(messages: [
                "Empty parameter: first_name_column or full_name_column is required"
            ])))
            return false
        }
        return true
    }

    private func buildEmailFinderFields(domainColumn: Int, options: ZBEmailFinderSendFileOptions?) -> [String: Any] {
        var fields: [String: Any] = ["domain_column": domainColumn]
        guard let options = options else { return fields }
        if let hasHeaderRow = options.hasHeaderRow {
            fields["has_header_row"] = hasHeaderRow ? "true" : "false"
        }
        if options.firstNameColumn > 0 { fields["first_name_column"] = options.firstNameColumn }
        if options.lastNameColumn > 0 { fields["last_name_column"] = options.lastNameColumn }
        if options.middleNameColumn > 0 { fields["middle_name_column"] = options.middleNameColumn }
        if options.fullNameColumn > 0 { fields["full_name_column"] = options.fullNameColumn }
        return fields
    }

    func sendDomainSearchFile(
        filePath: String,
        domainColumn: Int,
        options: ZBDomainSearchSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        if domainColumn < 1 {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: domain_column"])))
            return
        }
        sendBulkRootMultipart(
            url: "\(sdk.bulkApiRootUrl)/domain-search/sendfile",
            filePath: filePath,
            fields: buildDomainSearchFields(domainColumn: domainColumn, options: options),
            completion: completion
        )
    }

    func sendDomainSearchFileData(
        fileData: Data,
        fileName: String,
        domainColumn: Int,
        options: ZBDomainSearchSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        if domainColumn < 1 {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: domain_column"])))
            return
        }
        sendBulkRootMultipartData(
            url: "\(sdk.bulkApiRootUrl)/domain-search/sendfile",
            fileData: fileData,
            fileName: fileName,
            fields: buildDomainSearchFields(domainColumn: domainColumn, options: options),
            completion: completion
        )
    }

    private func buildDomainSearchFields(domainColumn: Int, options: ZBDomainSearchSendFileOptions?) -> [String: Any] {
        var fields: [String: Any] = ["domain_column": domainColumn]
        if let hasHeaderRow = options?.hasHeaderRow {
            fields["has_header_row"] = hasHeaderRow ? "true" : "false"
        }
        return fields
    }

    func bulkRootFileStatus(
        baseUrl: String,
        fileId: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBFileStatusResponse>) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        sdk.priority3SendJson(
            url: sdk.priority3QueryURL(base: "\(baseUrl)/filestatus", query: [
                "api_key": apiKey,
                "file_id": fileId,
            ]),
            completion: completion
        )
    }

    func bulkRootGetFile(
        baseUrl: String,
        fileId: String,
        downloadPath: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        let url = sdk.priority3QueryURL(base: "\(baseUrl)/getfile", query: [
            "api_key": apiKey,
            "file_id": fileId,
        ])
        sdk.priority3Download(url: url, downloadPath: downloadPath, completion: completion)
    }

    func bulkRootDeleteFile(
        baseUrl: String,
        fileId: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBDeleteFileResponse>) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        sdk.priority3SendJson(
            url: sdk.priority3QueryURL(base: "\(baseUrl)/deletefile", query: [
                "api_key": apiKey,
                "file_id": fileId,
            ]),
            completion: completion
        )
    }

    func sendListEvaluatorFile(
        filePath: String,
        emailAddressColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        if emailAddressColumn < 1 {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: email_address_column"])))
            return
        }
        sendBulkRootMultipart(
            url: "\(sdk.listEvaluatorBaseUrl)/",
            filePath: filePath,
            fields: ["email_address_column": emailAddressColumn],
            completion: completion
        )
    }

    func sendListEvaluatorFileData(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        if emailAddressColumn < 1 {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: email_address_column"])))
            return
        }
        sendBulkRootMultipartData(
            url: "\(sdk.listEvaluatorBaseUrl)/",
            fileData: fileData,
            fileName: fileName,
            fields: ["email_address_column": emailAddressColumn],
            completion: completion
        )
    }

    func getListEvaluatorResult(
        fileId: String,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        let trimmed = fileId.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: file_id"])))
            return
        }
        // The file id is one path segment, so a slash in it must stay encoded.
        sdk.priority3SendDictionary(
            url: sdk.priority3QueryURL(
                base: "\(sdk.listEvaluatorBaseUrl)/\(ZeroBounceSDK.escapePathSegment(trimmed))/",
                query: ["api_key": apiKey]
            ),
            completion: completion
        )
    }

    /// Submits a list the list evaluator has finished for bulk validation.
    ///
    /// LIVE: this takes the id of a finished evaluation as a form field, not an
    /// upload, and the trailing slash is part of the endpoint.
    func sendEvaluatedFile(
        fileId: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        let trimmed = fileId.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: file_id"])))
            return
        }
        sdk.priority3FormPostSendFile(
            url: "\(sdk.bulkApiBaseUrl)/send-evaluated-file/",
            formFields: ["api_key": apiKey, "file_id": trimmed],
            completion: completion
        )
    }

    func addFilter(
        rule: String,
        target: String,
        value: String,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        sdk.priority3FormPostDictionary(
            url: sdk.apiBaseUrl + "/filters/add",
            formFields: ["api_key": apiKey, "rule": rule, "target": target, "value": value],
            completion: completion
        )
    }

    /// LIVE: the listing answers with a JSON array, `[]` when no filters are
    /// set, so it cannot be carried as a dictionary.
    func listFilters(
        usePost: Bool,
        completion: @escaping (ZeroBounceSDK.ZBJsonResult) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        if usePost {
            sdk.priority3FormPostJson(
                url: sdk.apiBaseUrl + "/filters/list",
                formFields: ["api_key": apiKey],
                completion: completion
            )
        } else {
            sdk.priority3SendJson(
                url: sdk.priority3QueryURL(base: sdk.apiBaseUrl + "/filters/list", query: ["api_key": apiKey]),
                completion: completion
            )
        }
    }

    func deleteFilter(
        rule: String,
        target: String,
        value: String,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        sdk.priority3FormPostDictionary(
            url: sdk.apiBaseUrl + "/filters/delete",
            formFields: ["api_key": apiKey, "rule": rule, "target": target, "value": value],
            completion: completion
        )
    }

    /// LIVE: return_url is required, as it is on every other S3/SFTP job, so
    /// this goes through the same check. Without one the API answers HTTP 400
    /// "Provided return URL is not permitted: None".
    func validateS3File(
        options: ZBValidateS3FileOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard checkBulkJobRequiredFields(
            fileName: options.fileName,
            returnUrl: options.returnUrl,
            completion: completion
        ) else { return }
        postBulkRootForm(path: "/validateS3file", fields: buildValidateS3Fields(options: options), completion: completion)
    }

    /// LIVE: return_url is required here too. See `validateS3File`.
    func scoreS3File(
        options: ZBScoreS3FileOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard checkBulkJobRequiredFields(
            fileName: options.fileName,
            returnUrl: options.returnUrl,
            completion: completion
        ) else { return }
        var fields: [String: String] = [
            "file_name": options.fileName,
            "return_url": options.returnUrl
        ]
        putOptionalBool(&fields, key: "has_header_row", value: options.hasHeaderRow)
        putOptionalBool(&fields, key: "remove_duplicates", value: options.removeDuplicates)
        if let col = options.emailAddressColumn {
            fields["email_address_column"] = String(col)
        }
        postBulkRootForm(path: "/scoreS3file", fields: fields, completion: completion)
    }

    func listS3files(
        bucket: String?,
        search: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<[ZBS3ListFileEntry]>) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        var query: [String: String] = ["api_key": apiKey]
        if let bucket = bucket, !bucket.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            query["bucket"] = bucket
        }
        if let search = search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            query["search"] = search
        }
        let url = sdk.priority3QueryURL(base: sdk.bulkApiRootUrl + "/listS3files", query: query)
        sdk.priority3SendJson(url: url, completion: completion)
    }

    /// `export_bucket` is optional: pass nil to use the export bucket from
    /// your ZeroBounce settings, the way `exportSFTPFile` treats export_path.
    func exportS3File(
        fileId: String,
        exportBucket: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        exportBulkFile(
            path: "/exportS3file",
            destinationField: "export_bucket",
            fileId: fileId,
            destination: exportBucket,
            completion: completion
        )
    }

    // MARK: S3 email finder / domain search, SFTP/FTP bulk

    func emailFinderS3File(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        bulkRootFileJob(path: "/emailFinderS3file", options: options, completion: completion)
    }

    func domainSearchS3File(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        bulkRootFileJob(path: "/domainSearchS3file", options: options, completion: completion)
    }

    /// The server, path and protocol are never sent by the SDK; they come from
    /// your ZeroBounce settings.
    ///
    /// This is the one job whose file_name the docs list as optional: leave
    /// `options.fileName` nil to use the input bucket from those settings.
    func validateSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        bulkRootFileJob(path: "/validateSFTPfile", options: options, completion: completion)
    }

    func scoreSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        bulkRootFileJob(path: "/scoreSFTPfile", options: options, completion: completion)
    }

    func emailFinderSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        bulkRootFileJob(path: "/emailFinderSFTPfile", options: options, completion: completion)
    }

    func domainSearchSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        bulkRootFileJob(path: "/domainSearchSFTPfile", options: options, completion: completion)
    }

    /// Note the field name: this endpoint takes export_path, not the
    /// export_bucket that `exportS3File` sends. Pass nil to use the export path
    /// from your ZeroBounce settings.
    func exportSFTPFile(
        fileId: String,
        exportPath: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        exportBulkFile(
            path: "/exportSFTPfile",
            destinationField: "export_path",
            fileId: fileId,
            destination: exportPath,
            completion: completion
        )
    }

    /// The two fields every S3 and SFTP file job must carry. Reports what is
    /// missing and answers false when the caller has already been completed.
    ///
    /// LIVE: both are required on all of them — validateSFTPfile, whose
    /// file_name the docs call optional, and validateS3file and scoreS3file,
    /// whose return_url the docs call optional, included.
    private func checkBulkJobRequiredFields(
        fileName: String?,
        returnUrl: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) -> Bool {
        if (fileName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: file_name"])))
            return false
        }
        if (returnUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: return_url"])))
            return false
        }
        return true
    }

    /// POSTs one of the six documented S3 / SFTP file jobs on the bulkapi root.
    ///
    /// Booleans go on the wire as the strings "true"/"false", and an option the
    /// caller left unset is not sent at all.
    ///
    /// LIVE: file_name and return_url are required on every one of these jobs,
    /// validateSFTPfile included, although the docs call its file_name
    /// optional. Without either the API answers "Empty parameter: file_name" /
    /// "Empty parameter: return_url", so both are checked before sending.
    private func bulkRootFileJob(
        path: String,
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard checkBulkJobRequiredFields(
            fileName: options.fileName,
            returnUrl: options.returnUrl,
            completion: completion
        ) else { return }

        var fields: [String: String] = [
            "has_header_row": options.hasHeaderRow ? "true" : "false",
            "file_name": options.fileName!,
            "return_url": options.returnUrl!
        ]
        if let removeDuplicates = options.removeDuplicates {
            fields["remove_duplicates"] = removeDuplicates ? "true" : "false"
        }

        postBulkRootForm(path: path, fields: fields, completion: completion)
    }

    private func exportBulkFile(
        path: String,
        destinationField: String,
        fileId: String,
        destination: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        if fileId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: file_id"])))
            return
        }
        if let destination = destination,
           destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: \(destinationField)"])))
            return
        }

        var fields: [String: String] = ["file_id": fileId]
        if let destination = destination { fields[destinationField] = destination }
        postBulkRootForm(path: path, fields: fields, completion: completion)
    }

    // MARK: Inbox Placement Tester (/api/ipt)
    //
    // Its own host, camelCase JSON bodies, and PUT and DELETE as well as GET
    // and POST. Spends the account's inbox-test credits.
    //
    // LIVE: it authenticates with an Authorization: Bearer header. Sent as an
    // api_key query parameter the request is rejected as unauthorized, and the
    // key would end up in whatever logs the query string.

    func getInboxPlacementProviders(completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) {
        inboxPlacementRequest(method: "GET", path: "/providers", query: [:], body: nil, completion: completion)
    }

    func getInboxPlacementTestTypes(completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) {
        inboxPlacementRequest(method: "GET", path: "/test-types", query: [:], body: nil, completion: completion)
    }

    func createInboxPlacementTest(
        name: String,
        options: ZBCreateInboxPlacementTestOptions?,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: name"])))
            return
        }
        if trimmedName.count > 64 {
            completion(.Failure(ZBError.decodeError(messages: [
                "Invalid parameter: name (must be at most 64 characters)"
            ])))
            return
        }
        if let testType = options?.testType, testType < 1 || testType > 3 {
            completion(.Failure(ZBError.decodeError(messages: [
                "Invalid parameter: testType (must be 1, 2 or 3)"
            ])))
            return
        }
        // Test type 1 is the one you send the email for yourself, so the
        // address it will come from has to be known up front.
        if options?.testType == 1,
           (options?.senderEmail?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty {
            completion(.Failure(ZBError.decodeError(messages: [
                "Empty parameter: senderEmail is required when testType is 1"
            ])))
            return
        }
        var body: [String: Any] = ["name": name]
        if let options = options {
            if let testType = options.testType { body["testType"] = testType }
            if let senderEmail = options.senderEmail { body["senderEmail"] = senderEmail }
            if let providerIds = options.providerIds { body["providerIds"] = providerIds }
            if let seedIds = options.seedIds { body["seedIds"] = seedIds }
            if let providers = options.providers {
                body["providers"] = providers.map { ["id": $0.id, "maxSeeds": $0.maxSeeds] }
            }
            if let webhookUrl = options.webhookUrl { body["webhookUrl"] = webhookUrl }
        }
        inboxPlacementRequest(method: "POST", path: "/test", query: [:], body: body, completion: completion)
    }

    func getInboxPlacementTest(
        testId: String,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        guard let segment = inboxPlacementTestSegment(testId, completion) else { return }
        inboxPlacementRequest(method: "GET", path: "/test/\(segment)", query: [:], body: nil, completion: completion)
    }

    func listInboxPlacementTests(
        options: ZBListInboxPlacementTestsOptions?,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        var query: [String: String] = [:]
        if let options = options {
            if let status = options.status {
                let trimmed = status.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed != "running" && trimmed != "finished" {
                    completion(.Failure(ZBError.decodeError(messages: [
                        "Invalid parameter: status (must be running or finished)"
                    ])))
                    return
                }
                query["status"] = trimmed
            }
            if let pageSize = options.pageSize, pageSize < 1 || pageSize > 100 {
                completion(.Failure(ZBError.decodeError(messages: [
                    "Invalid parameter: page_size (must be between 1 and 100)"
                ])))
                return
            }
            if let createdAfter = options.createdAfter { query["createdAfter"] = createdAfter }
            if let createdBefore = options.createdBefore { query["createdBefore"] = createdBefore }
            if let page = options.page { query["page"] = String(page) }
            // LIVE: the page size is page_size. Sent as pageSize, the way the
            // other filters are spelled, it is accepted and then ignored, and
            // the whole list comes back unpaginated.
            if let pageSize = options.pageSize { query["page_size"] = String(pageSize) }
        }
        // LIVE: the listing is GET /tests (plural). /test is the single-test
        // path and answers 'Method "GET" not allowed'.
        inboxPlacementRequest(method: "GET", path: "/tests", query: query, body: nil, completion: completion)
    }

    func deleteInboxPlacementTest(
        testId: String,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        guard let segment = inboxPlacementTestSegment(testId, completion) else { return }
        inboxPlacementRequest(method: "DELETE", path: "/test/\(segment)", query: [:], body: nil, completion: completion)
    }

    func getInboxPlacementWebhook(completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) {
        inboxPlacementRequest(method: "GET", path: "/webhook", query: [:], body: nil, completion: completion)
    }

    func setInboxPlacementWebhook(
        webhookUrl: String,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        if webhookUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: webhook_url"])))
            return
        }
        inboxPlacementRequest(
            method: "PUT", path: "/webhook", query: [:],
            body: ["webhookUrl": webhookUrl], completion: completion
        )
    }

    private func inboxPlacementTestSegment(
        _ testId: String,
        _ completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) -> String? {
        let trimmed = testId.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: test_id"])))
            return nil
        }
        return ZeroBounceSDK.escapePathSegment(trimmed)
    }

    private func inboxPlacementRequest(
        method: String,
        path: String,
        query: [String: String],
        body: [String: Any]?,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        sdk.priority3JsonDictionaryRequest(
            method: method,
            url: sdk.priority3QueryURL(base: sdk.inboxPlacementBaseUrl + path, query: query),
            body: body,
            extraHeaders: ["Authorization": "Bearer \(apiKey)"],
            completion: completion
        )
    }

    private func buildValidateS3Fields(options: ZBValidateS3FileOptions) -> [String: String] {
        var fields: [String: String] = [
            "file_name": options.fileName,
            "return_url": options.returnUrl
        ]
        putOptionalBool(&fields, key: "has_header_row", value: options.hasHeaderRow)
        putOptionalBool(&fields, key: "remove_duplicates", value: options.removeDuplicates)
        if let col = options.emailAddressColumn {
            fields["email_address_column"] = String(col)
        }
        if options.firstNameColumn > 0 { fields["first_name_column"] = String(options.firstNameColumn) }
        if options.lastNameColumn > 0 { fields["last_name_column"] = String(options.lastNameColumn) }
        if options.genderColumn > 0 { fields["gender_column"] = String(options.genderColumn) }
        if options.ipAddressColumn > 0 { fields["ip_address_column"] = String(options.ipAddressColumn) }
        if let allowPhase2 = options.allowPhase2 { fields["allow_phase_2"] = String(allowPhase2) }
        return fields
    }

    private func putOptionalBool(_ fields: inout [String: String], key: String, value: Bool?) {
        if let value = value { fields[key] = String(value) }
    }

    private func postBulkRootForm(
        path: String,
        fields: [String: String],
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        var form = fields
        form["api_key"] = apiKey
        sdk.priority3FormPostSendFile(url: sdk.bulkApiRootUrl + path, formFields: form, completion: completion)
    }

    private func sendBulkRootMultipart(
        url: String,
        filePath: String,
        fields: [String: Any],
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        var parameters = fields
        parameters["api_key"] = apiKey
        do {
            let request = try ZBMultiPartRequest.createFileRequest(
                url: url,
                parameters: parameters,
                filePathKey: "file",
                paths: [filePath]
            )
            sdk.priority3SendJsonRequest(request: request, completion: completion)
        } catch {
            completion(.Failure(error))
        }
    }

    private func sendBulkRootMultipartData(
        url: String,
        fileData: Data,
        fileName: String,
        fields: [String: Any],
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        var parameters = fields
        parameters["api_key"] = apiKey
        do {
            let request = try ZBMultiPartRequest.createFileRequestWithData(
                url: url,
                parameters: parameters,
                filePathKey: "file",
                fileData: fileData,
                fileName: fileName
            )
            sdk.priority3SendJsonRequest(request: request, completion: completion)
        } catch {
            completion(.Failure(error))
        }
    }
}
