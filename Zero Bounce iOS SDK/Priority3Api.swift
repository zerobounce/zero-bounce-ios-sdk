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
        if domainColumn < 1 {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: domain_column"])))
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
        if domainColumn < 1 {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: domain_column"])))
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

    func sendEvaluatedFile(
        filePath: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        sendBulkRootMultipart(
            url: "\(sdk.bulkApiBaseUrl)/send-evaluated-file/",
            filePath: filePath,
            fields: [:],
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

    func listFilters(
        usePost: Bool,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        guard let apiKey = sdk.apiKey else {
            completion(.Failure(ZBError.notInitialized))
            return
        }
        if usePost {
            sdk.priority3FormPostDictionary(
                url: sdk.apiBaseUrl + "/filters/list",
                formFields: ["api_key": apiKey],
                completion: completion
            )
        } else {
            sdk.priority3SendDictionary(
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

    func validateS3File(
        options: ZBValidateS3FileOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        if options.fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: file_name"])))
            return
        }
        postBulkRootForm(path: "/validateS3file", fields: buildValidateS3Fields(options: options), completion: completion)
    }

    func scoreS3File(
        options: ZBScoreS3FileOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        if options.fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: file_name"])))
            return
        }
        var fields: [String: String] = ["file_name": options.fileName]
        putOptionalBool(&fields, key: "has_header_row", value: options.hasHeaderRow)
        putOptionalBool(&fields, key: "remove_duplicates", value: options.removeDuplicates)
        putOptionalBool(&fields, key: "remove_duplicate", value: options.removeDuplicate)
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

    func exportS3File(
        fileId: String,
        exportBucket: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        if fileId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: file_id"])))
            return
        }
        if exportBucket.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: export_bucket"])))
            return
        }
        postBulkRootForm(
            path: "/exportS3file",
            fields: ["file_id": fileId, "export_bucket": exportBucket],
            completion: completion
        )
    }

    // MARK: S3 email finder / domain search, SFTP/FTP bulk

    func emailFinderS3File(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        bulkRootFileJob(path: "/emailFinderS3file", options: options, fileNameRequired: true, completion: completion)
    }

    func domainSearchS3File(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        bulkRootFileJob(path: "/domainSearchS3file", options: options, fileNameRequired: true, completion: completion)
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
        bulkRootFileJob(path: "/validateSFTPfile", options: options, fileNameRequired: false, completion: completion)
    }

    func scoreSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        bulkRootFileJob(path: "/scoreSFTPfile", options: options, fileNameRequired: true, completion: completion)
    }

    func emailFinderSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        bulkRootFileJob(path: "/emailFinderSFTPfile", options: options, fileNameRequired: true, completion: completion)
    }

    func domainSearchSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        bulkRootFileJob(path: "/domainSearchSFTPfile", options: options, fileNameRequired: true, completion: completion)
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

    /// POSTs one of the six documented S3 / SFTP file jobs on the bulkapi root.
    ///
    /// Booleans go on the wire as the strings "true"/"false", and an option the
    /// caller left unset is not sent at all.
    private func bulkRootFileJob(
        path: String,
        options: ZBBulkFileJobOptions,
        fileNameRequired: Bool,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        let blank = options.fileName != nil
            && options.fileName!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if (options.fileName == nil && fileNameRequired) || blank {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: file_name"])))
            return
        }

        var fields: [String: String] = ["has_header_row": options.hasHeaderRow ? "true" : "false"]
        if let fileName = options.fileName { fields["file_name"] = fileName }
        if let removeDuplicates = options.removeDuplicates {
            fields["remove_duplicates"] = removeDuplicates ? "true" : "false"
        }
        if let returnUrl = options.returnUrl { fields["return_url"] = returnUrl }

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
    // Its own host, the API key on the query string, camelCase JSON bodies, and
    // PUT and DELETE as well as GET and POST. Spends the account's inbox-test
    // credits.

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
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completion(.Failure(ZBError.decodeError(messages: ["Empty parameter: name"])))
            return
        }
        var body: [String: Any] = ["name": name]
        if let options = options {
            if let testType = options.testType { body["testType"] = testType }
            if let senderEmail = options.senderEmail { body["senderEmail"] = senderEmail }
            if let providerIds = options.providerIds { body["providerIds"] = providerIds }
            if let seedIds = options.seedIds { body["seedIds"] = seedIds }
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
            if let status = options.status { query["status"] = status }
            if let page = options.page { query["page"] = String(page) }
            if let pageSize = options.pageSize { query["pageSize"] = String(pageSize) }
        }
        inboxPlacementRequest(method: "GET", path: "/test", query: query, body: nil, completion: completion)
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
        var params = query
        // The API key goes on the query string here, not in the body.
        params["api_key"] = apiKey
        sdk.priority3JsonDictionaryRequest(
            method: method,
            url: sdk.priority3QueryURL(base: sdk.inboxPlacementBaseUrl + path, query: params),
            body: body,
            completion: completion
        )
    }

    private func buildValidateS3Fields(options: ZBValidateS3FileOptions) -> [String: String] {
        var fields: [String: String] = ["file_name": options.fileName]
        putOptionalBool(&fields, key: "has_header_row", value: options.hasHeaderRow)
        putOptionalBool(&fields, key: "remove_duplicates", value: options.removeDuplicates)
        putOptionalBool(&fields, key: "remove_duplicate", value: options.removeDuplicate)
        if let col = options.emailAddressColumn {
            fields["email_address_column"] = String(col)
        }
        if let returnUrl = options.returnUrl { fields["return_url"] = returnUrl }
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
