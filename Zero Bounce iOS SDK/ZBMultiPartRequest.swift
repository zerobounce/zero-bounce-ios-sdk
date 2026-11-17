//
//  ZBMultiPartRequest.swift
//  Zero Bounce iOS SDK
//
//  Created by ZeroBounce on 09/07/2019.
//  Copyright © 2019 ZeroBounce. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

internal class ZBMultiPartRequest {
    
    /// Create request
    ///
    /// - parameter parameters:   The optional dictionary containing keys and values to be passed to web service
    /// - parameter filePathKey:  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
    /// - parameter paths:        The optional array of file paths of the files to be uploaded
    ///
    /// - returns:            The `URLRequest` that was created
    
    static internal func createFileRequest(url:String, parameters: [String: Any]?, filePathKey: String, paths: [String]) throws -> URLRequest {
        let boundary = generateBoundaryString()
        try validate(parameters: parameters, filePathKey: filePathKey,
                     fileNames: paths.map { URL(fileURLWithPath: $0).lastPathComponent })
        
        guard let requestURL = URL(string: url) else { throw ZBError.invalidEndpoint }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.timeoutInterval = ZeroBounceSDK.requestTimeout
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try createBody(with: parameters, filePathKey: filePathKey, paths: paths, boundary: boundary)
        
        return request
    }
    
    /// Create request with file data (e.g. in-memory CSV) instead of file path.
    static internal func createFileRequestWithData(url: String, parameters: [String: Any]?, filePathKey: String, fileData: Data, fileName: String) throws -> URLRequest {
        let boundary = generateBoundaryString()
        try validate(parameters: parameters, filePathKey: filePathKey, fileNames: [fileName])
        
        guard let requestURL = URL(string: url) else { throw ZBError.invalidEndpoint }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.timeoutInterval = ZeroBounceSDK.requestTimeout
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createBodyWithData(parameters: parameters, filePathKey: filePathKey, fileData: fileData, fileName: fileName, boundary: boundary)
        
        return request
    }
    
    static private func createBodyWithData(parameters: [String: Any]?, filePathKey: String, fileData: Data, fileName: String, boundary: String) -> Data {
        var body = Data()
        
        if let parameters = parameters {
            for (key, value) in parameters {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        let mimetype = mimeTypeForFile(name: fileName)
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimetype)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
        
        body.append("--\(boundary)--\r\n")
        return body
    }
    
    /// The text of the refusal: fixed, so it never quotes a value (an api_key
    /// is one of them).
    internal static let refusedFieldText =
        "A form field name, a form value or a file name must not contain CR, LF or NUL, and a file name must not contain a double quote"

    /// Throws when a form field name, a form value or a file name could break
    /// out of its multipart part: CR, LF or NUL in any of them, or `"` in a
    /// file name (a field name is quoted too, so `"` is refused there as well).
    internal static func validate(parameters: [String: Any]?, filePathKey: String, fileNames: [String]) throws {
        func bad(_ text: String, quote: Bool) -> Bool {
            text.unicodeScalars.contains { $0 == "\r" || $0 == "\n" || $0 == "\0" || (quote && $0 == "\"") }
        }
        for (key, value) in parameters ?? [:] {
            if bad(key, quote: true) || bad("\(value)", quote: false) {
                throw ZBError.decodeError(messages: [refusedFieldText])
            }
        }
        if bad(filePathKey, quote: true) { throw ZBError.decodeError(messages: [refusedFieldText]) }
        for name in fileNames where bad(name, quote: true) {
            throw ZBError.decodeError(messages: [refusedFieldText])
        }
    }

    private static func mimeTypeForFile(name: String) -> String {
        let pathExtension = (name as NSString).pathExtension
        if let mimetype = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
            return mimetype
        }
        return "text/csv"
    }
    
    /// Create body of the `multipart/form-data` request
    ///
    /// - parameter parameters:   The optional dictionary containing keys and values to be passed to web service
    /// - parameter filePathKey:  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
    /// - parameter paths:        The optional array of file paths of the files to be uploaded
    /// - parameter boundary:     The `multipart/form-data` boundary
    ///
    /// - returns:                The `Data` of the body of the request
    
    static private func createBody(with parameters: [String: Any]?, filePathKey: String, paths: [String], boundary: String) throws -> Data {
        var body = Data()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        for path in paths {
            let url = URL(fileURLWithPath: path)
            let filename = url.lastPathComponent
            let data = try Data(contentsOf: url)
            let mimetype = mimeType(for: path)
            
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }
    
    /// Create boundary string for multipart/form-data request
    ///
    /// - returns:            The boundary string that consists of "Boundary-" followed by a UUID string.
    
    static internal func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    /// Determine mime type on the basis of extension of a file.
    ///
    /// This requires `import UniformTypeIdentifiers`.
    ///
    /// - parameter path:         The path of the file for which we are going to determine the mime type.
    ///
    /// - returns:                Returns the mime type if successful. Returns `application/octet-stream` if unable to determine mime type.
    
    private static func mimeType(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let mimetype = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
            return mimetype
        }
        return "application/octet-stream"
    }
}

internal extension Data {
    
    /// Append string to Data
    ///
    /// Rather than littering my code with calls to `data(using: .utf8)` to convert `String` values to `Data`, this wraps it in a nice convenient little extension to Data. This defaults to converting using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `Data`.
    
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}
