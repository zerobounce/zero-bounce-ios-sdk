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
        if options.hasHeaderRow == true { fields["has_header_row"] = "true" }
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
        if options?.hasHeaderRow == true { fields["has_header_row"] = "true" }
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
            url: "\(sdk.bulkApiBaseUrl)/listevaluator/",
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
            url: "\(sdk.bulkApiBaseUrl)/listevaluator/",
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
        sdk.priority3SendDictionary(
            url: sdk.priority3QueryURL(base: "\(sdk.bulkApiBaseUrl)/listevaluator/\(fileId)/", query: ["api_key": apiKey]),
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
