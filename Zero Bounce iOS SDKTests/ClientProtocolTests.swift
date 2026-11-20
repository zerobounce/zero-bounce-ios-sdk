//
//  ClientProtocolTests.swift
//  Zero Bounce iOS SDKTests
//
//  `ZeroBounceSDKProtocol` and `ZeroBounceWarmupProtocol`: app code that
//  holds the protocol takes a fake, and each protocol keeps up with its
//  class. Nothing here reaches the network.
//
//  A plain import, not `@testable`: the fakes must compile against the public
//  API alone, the way an app's would.
//

import XCTest
import Zero_Bounce_iOS_SDK

// MARK: - The drift guard

/// The public surface of a type as its source declares it.
///
/// Swift has no runtime reflection over methods, so this reads the sources the
/// way `publicRequestMethodsInSources` does. The compiler already refuses a
/// requirement the class does not implement with the same signature (the
/// conformance is in the SDK). This covers the other direction: a public
/// method added to the class but not to its protocol, a signature changed on
/// one side only, and a default argument the protocol extension does not
/// mirror.
///
/// It relies on the sources' layout: members indented four spaces inside a
/// top-level declaration, a method's body opening with `{`. A member declared
/// another way is not seen, so the tests require a minimum count and check the
/// scan against known signatures; a scan that finds nothing fails.
private struct SourceSurface {
    /// A method: its attributes and declaration with whitespace, `public`,
    /// type qualifiers and default values normalized away.
    struct Method: Hashable {
        let name: String
        let key: String
        /// External label and default value of each defaulted parameter.
        let defaults: [(label: String, value: String)]
        /// The key with the defaulted parameters left out.
        let keyWithoutDefaults: String
        let body: String

        static func == (lhs: Method, rhs: Method) -> Bool { lhs.key == rhs.key }
        func hash(into hasher: inout Hasher) { hasher.combine(key) }
    }

    var methods: [Method] = []
    /// Public members that are not methods or nested types (properties,
    /// initializers), and static methods, by name.
    var otherMembers: Set<String> = []

    static let sourcesDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Zero Bounce iOS SDK")

    /// Members of `kind name` (for example `class ZeroBounceSDK`, which also
    /// takes in every `extension ZeroBounceSDK`) across all SDK sources.
    /// Method bodies are read only when `bodies` is set; the class's own are
    /// skipped, since a brace in a string literal would throw the count off.
    static func scan(_ name: String, kinds: Set<String>, bodies: Bool = false) throws -> SourceSurface {
        let files = try FileManager.default.contentsOfDirectory(at: sourcesDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        var surface = SourceSurface()
        let topLevel = try NSRegularExpression(
            pattern: #"^(public\s+)?(?:final\s+)?(class|struct|enum|extension|protocol)\s+(\w+)"#)
        let member = try NSRegularExpression(
            pattern: #"^    ((?:(?:public|static|final|class|override|nonisolated)\s+)*)(func|var|let|init|subscript|enum|struct|class|typealias)\b"#)
        for file in files {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")
            var inside = false
            // Members of a protocol, or of a `public extension`, are public
            // without the keyword.
            var publicByDefault = false
            var index = 0
            while index < lines.count {
                let line = lines[index]
                let range = NSRange(line.startIndex..., in: line)
                if let match = topLevel.firstMatch(in: line, range: range) {
                    let kind = (line as NSString).substring(with: match.range(at: 2))
                    let typeName = (line as NSString).substring(with: match.range(at: 3))
                    inside = typeName == name && kinds.contains(kind) && !line.hasSuffix("{}")
                    publicByDefault = kind == "protocol"
                        || (kind == "extension" && match.range(at: 1).location != NSNotFound)
                } else if line.hasPrefix("}") {
                    inside = false
                } else if inside, let match = member.firstMatch(in: line, range: range) {
                    let modifiers = (line as NSString).substring(with: match.range(at: 1))
                    let kind = (line as NSString).substring(with: match.range(at: 2))
                    let isPublic = modifiers.contains("public") || publicByDefault
                    let isStatic = modifiers.contains("static") || modifiers.contains("class ")
                    if isPublic && kind == "func" && !isStatic {
                        var attributes: [String] = []
                        var above = index - 1
                        while above >= 0, lines[above].hasPrefix("    @") {
                            attributes.insert(lines[above].trimmingCharacters(in: .whitespaces), at: 0)
                            above -= 1
                        }
                        let (method, next) = readMethod(lines, from: index, attributes: attributes, body: bodies)
                        surface.methods.append(method)
                        index = next
                        continue
                    } else if isPublic && ["func", "var", "let", "init", "subscript"].contains(kind) {
                        let rest = line[line.index(line.startIndex, offsetBy: match.range.upperBound)...]
                        let word = rest.trimmingCharacters(in: .whitespaces).prefix { $0.isLetter || $0.isNumber || $0 == "_" }
                        surface.otherMembers.insert(kind == "init" ? "init" : String(word))
                    }
                }
                index += 1
            }
        }
        return surface
    }

    /// Reads one method declaration starting at `start`, and its body when it
    /// has one. Returns the line after it.
    private static func readMethod(_ lines: [String], from start: Int, attributes: [String], body wantBody: Bool) -> (Method, Int) {
        var declaration = ""
        var body = ""
        var depth = 0
        var braces = 0
        var inBody = false
        var index = start
        lineLoop: while index < lines.count {
            let line = lines[index]
            for character in line {
                if inBody {
                    body.append(character)
                    if character == "{" { braces += 1 }
                    if character == "}" { braces -= 1; if braces == 0 { index += 1; break lineLoop } }
                    continue
                }
                if character == "(" { depth += 1 }
                if character == ")" { depth -= 1 }
                if character == "{" && depth == 0 {
                    guard wantBody else { index += 1; break lineLoop }
                    inBody = true; braces = 1; body.append(character); continue
                }
                declaration.append(character)
            }
            index += 1
            if inBody { body.append("\n"); continue }
            // A requirement has no body: it ends with its line once the
            // parameter list is closed, unless the next line continues it.
            if depth == 0, declaration.contains(")") {
                let next = index < lines.count ? lines[index].trimmingCharacters(in: .whitespaces) : ""
                if !["->", "throws", "async", "rethrows", "where"].contains(where: { next.hasPrefix($0) }) { break }
            }
            declaration.append(" ")
        }
        return (makeMethod(declaration, attributes: attributes, body: body), index)
    }

    private static func makeMethod(_ declaration: String, attributes: [String], body: String) -> Method {
        let text = declaration
        let open = text.firstIndex(of: "(")!
        var depth = 0
        var params: [String] = []
        var current = ""
        var close = open
        var position = open
        while position < text.endIndex {
            let character = text[position]
            if character == "(" || character == "[" || character == "<" {
                depth += 1
                if depth == 1 { position = text.index(after: position); continue }
            } else if (character == ")" || character == "]" || (character == ">" && text[text.index(before: position)] != "-")) {
                depth -= 1
                if depth == 0 { params.append(current); close = position; break }
            } else if character == "," && depth == 1 {
                params.append(current); current = ""
                position = text.index(after: position); continue
            }
            current.append(character)
            position = text.index(after: position)
        }
        let head = normalize(String(text[..<open]))
        let tail = normalize(String(text[text.index(after: close)...]))
        var plain: [String] = []
        var kept: [String] = []
        var defaults: [(label: String, value: String)] = []
        for param in params.map({ normalize($0) }).filter({ !$0.isEmpty }) {
            if let equals = param.range(of: " = ") {
                let declared = String(param[..<equals.lowerBound])
                let label = String(declared.prefix { $0 != " " && $0 != ":" })
                defaults.append((label, String(param[equals.upperBound...])))
                plain.append(declared)
            } else {
                plain.append(param)
                kept.append(param)
            }
        }
        let prefix = attributes.map(normalize).joined(separator: " ")
        func key(_ list: [String]) -> String {
            (prefix.isEmpty ? "" : prefix + " ") + head + "(" + list.joined(separator: ", ") + ")" + (tail.isEmpty ? "" : " " + tail)
        }
        let name = String(head.split(separator: " ").last ?? "")
        return Method(name: name, key: key(plain), defaults: defaults, keyWithoutDefaults: key(kept), body: body)
    }

    /// Whitespace, `public` and the `ZeroBounceSDK.` / `ZeroBounceWarmup.`
    /// qualifiers of the nested result types do not change a signature.
    static func normalize(_ text: String) -> String {
        var result = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\bpublic "#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\b(ZeroBounceSDK|ZeroBounceWarmup)\.(?=ZB)"#, with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\s*:\s*"#, with: ": ", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\s*,\s*"#, with: ", ", options: .regularExpression)
        result = result.replacingOccurrences(of: #"([(\[<])\s+"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\s+([)\]>])"#, with: "$1", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespaces)
    }
}

final class ClientProtocolDriftTests: XCTestCase {

    func testZeroBounceSDKProtocolMatchesTheClass() throws {
        try assertProtocol(
            "ZeroBounceSDKProtocol", matches: "ZeroBounceSDK",
            // Setup and configuration, not API calls.
            excluded: ["init", "initialize", "setListEvaluatorBaseUrl", "setInboxPlacementBaseUrl",
                       "shared", "setSessionConfiguration", "customMirror"],
            atLeast: 64)
    }

    func testZeroBounceWarmupProtocolMatchesTheClass() throws {
        try assertProtocol(
            "ZeroBounceWarmupProtocol", matches: "ZeroBounceWarmup",
            excluded: ["init", "initialize", "shared", "selfManaged", "zbManaged", "baseUrl", "customMirror"],
            atLeast: 26)
    }

    /// The guard itself: a scan that missed a method, or a normalization that
    /// made two different signatures equal, would let drift through.
    func testTheScanTellsSignaturesApart() throws {
        let surface = try SourceSurface.scan("ZeroBounceSDK", kinds: ["class", "extension"])
        let validate = surface.methods.filter { $0.name == "validate" }
        XCTAssertEqual(validate.count, 2, "both validate overloads")
        XCTAssertEqual(Set(validate.map(\.key)).count, 2)
        XCTAssertTrue(validate.contains {
            $0.key == "func validate(email: String, ipAddress: String?, completion: @escaping (ZBResult<ZBValidateResponse>) -> ())"
        }, validate.map(\.key).joined(separator: "\n"))
        XCTAssertTrue(validate.allSatisfy { $0.defaults.map(\.label) == ["ipAddress"] && $0.defaults.map(\.value) == ["nil"] })
        let guess = try XCTUnwrap(surface.methods.first { $0.name == "guessFormat" })
        XCTAssertTrue(guess.key.hasPrefix("@available(*, deprecated"), guess.key)
        XCTAssertNotEqual(
            SourceSurface.normalize("func f(a: Int, completion: @escaping (ZBResult<A>) -> ())"),
            SourceSurface.normalize("func f(a: Int?, completion: @escaping (ZBResult<A>) -> ())"))
        XCTAssertEqual(
            SourceSurface.normalize("func f(\n    a: [String:String],\n    completion: @escaping (ZeroBounceSDK.ZBResult<A>) -> ()\n)"),
            SourceSurface.normalize("public func f(a: [String: String], completion: @escaping (ZBResult<A>) -> ())"))
    }

    private func assertProtocol(
        _ protocolName: String, matches className: String, excluded: Set<String>, atLeast minimum: Int,
        file: StaticString = #filePath, line: UInt = #line
    ) throws {
        let type = try SourceSurface.scan(className, kinds: ["class", "extension"])
        let requirements = try SourceSurface.scan(protocolName, kinds: ["protocol"])
        let conveniences = try SourceSurface.scan(protocolName, kinds: ["extension"], bodies: true)

        XCTAssertGreaterThanOrEqual(requirements.methods.count, minimum,
                                    "the scan found too few requirements in \(protocolName)", file: file, line: line)

        let api = type.methods.filter { !excluded.contains($0.name) }
        let classKeys = Set(api.map(\.key))
        let protocolKeys = Set(requirements.methods.map(\.key))
        XCTAssertEqual(requirements.methods.count, protocolKeys.count, "a requirement is declared twice", file: file, line: line)
        for missing in classKeys.subtracting(protocolKeys).sorted() {
            XCTFail("\(className) has a public method \(protocolName) lacks (add it, with its doc comment, or exclude it here if it is setup):\n\(missing)",
                    file: file, line: line)
        }
        for extra in protocolKeys.subtracting(classKeys).sorted() {
            XCTFail("\(protocolName) has a requirement that matches no public method of \(className):\n\(extra)",
                    file: file, line: line)
        }
        for name in excluded.intersection(requirements.methods.map(\.name)) {
            XCTFail("\(name) is excluded as setup but is a requirement of \(protocolName)", file: file, line: line)
        }

        // A public property, initializer or static method is setup by
        // definition; a new one has to be named here before it is left out.
        for member in type.otherMembers.union(type.methods.map(\.name)).subtracting(api.map(\.name)).sorted()
        where !excluded.contains(member) {
            XCTFail("\(className).\(member) is public but neither a requirement of \(protocolName) nor excluded here",
                    file: file, line: line)
        }

        // A protocol cannot declare default arguments, so for each method that
        // has them the extension offers the overload that leaves them all out,
        // passing the class's own default values.
        let withDefaults = api.filter { !$0.defaults.isEmpty }
        XCTAssertEqual(conveniences.methods.count, withDefaults.count,
                       "one convenience overload per method with default arguments", file: file, line: line)
        for method in withDefaults {
            guard let overload = conveniences.methods.first(where: { $0.key == method.keyWithoutDefaults }) else {
                XCTFail("the \(protocolName) extension has no overload without the default arguments of:\n\(method.key)\nexpected:\n\(method.keyWithoutDefaults)",
                        file: file, line: line)
                continue
            }
            for (label, value) in method.defaults {
                XCTAssertTrue(SourceSurface.normalize(overload.body).contains("\(label): \(value)"),
                              "\(overload.key) must pass \(label): \(value), the class's default", file: file, line: line)
            }
            XCTAssertTrue(overload.body.contains("\(method.name)("), file: file, line: line)
        }
    }
}

// MARK: - Fakes

private enum FakeError: Error { case notStubbed }

/// App code the way the README shows it: it holds the protocol, not the class.
private struct SignupGate {
    let client: any ZeroBounceSDKProtocol

    func accepts(_ email: String, done: @escaping (Bool) -> Void) {
        client.validate(email: email) { result in
            if case .Success(let response) = result {
                done(response.status == .valid)
            } else {
                done(false)
            }
        }
    }
}

private struct WarmupDashboard {
    let client: any ZeroBounceWarmupProtocol

    func accountCount(done: @escaping (Int?) -> Void) {
        client.listSendingAccounts { result in
            if case .Success(let body) = result, let accounts = body as? [Any] {
                done(accounts.count)
            } else {
                done(nil)
            }
        }
    }
}

/// Implements every requirement: the ones a test stubs answer with the stub,
/// the rest record the call and fail. An app's fake can do the same, or
/// `fatalError()` in the methods its code never calls.
private final class FakeZeroBounceSDK: ZeroBounceSDKProtocol {
    private(set) var calls: [String] = []
    private(set) var validated: [(email: String, ipAddress: String?)] = []
    var validateResult: ZeroBounceSDK.ZBResult<ZBValidateResponse>?

    private func record(_ call: String) { calls.append(call) }

    func validate(
        email: String,
        ipAddress: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBValidateResponse>) -> ()
    ) {
        record(#function)
        validated.append((email, ipAddress))
        completion(validateResult ?? .Failure(FakeError.notStubbed))
    }

    func validate(
        email: String,
        ipAddress: String?,
        options: ZBValidateOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBValidateResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func validateBatch(
        emails: [[String:String]],
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBValidateBatchResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func validateBatch(
        emails: [[String:String]],
        options: ZBValidateOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBValidateBatchResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func findEmail(
        domain: String,
        firstName: String?,
        middleName: String?,
        lastName: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func findEmail(
        companyName: String,
        firstName: String?,
        middleName: String?,
        lastName: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func findDomain(
        domain: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBDomainSearchResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func findDomain(
        companyName: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBDomainSearchResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func guessFormat(
        domain: String,
        firstName: String?,
        middleName: String?,
        lastName: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBEmailFinderResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getCredits(completion: @escaping (ZeroBounceSDK.ZBResult<ZBCreditsResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getApiUsage(
        startDate: Date,
        endDate: Date,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetApiUsageResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getActivityData(email: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBActivityDataResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func scoreEmail(email: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBScoreEmailResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func scoreEmailPost(email: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBScoreEmailResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func sendEmailFinderFile(
        filePath: String,
        domainColumn: Int,
        options: ZBEmailFinderSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func sendEmailFinderFileData(
        fileData: Data,
        fileName: String,
        domainColumn: Int,
        options: ZBEmailFinderSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func emailFinderFileStatus(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBFileStatusResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func emailFinderGetFile(
        fileId: String,
        downloadPath: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func emailFinderDeleteFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBDeleteFileResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func sendDomainSearchFile(
        filePath: String,
        domainColumn: Int,
        options: ZBDomainSearchSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func sendDomainSearchFileData(
        fileData: Data,
        fileName: String,
        domainColumn: Int,
        options: ZBDomainSearchSendFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func domainSearchFileStatus(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBFileStatusResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func domainSearchGetFile(
        fileId: String,
        downloadPath: String,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func domainSearchDeleteFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBDeleteFileResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func sendListEvaluatorFile(
        filePath: String,
        emailAddressColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func sendListEvaluatorFileData(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getListEvaluatorResult(fileId: String, completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func sendEvaluatedFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func addFilter(
        rule: String,
        target: String,
        value: String,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func listFilters(usePost: Bool, completion: @escaping (ZeroBounceSDK.ZBJsonResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func deleteFilter(
        rule: String,
        target: String,
        value: String,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func validateS3File(
        options: ZBValidateS3FileOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func scoreS3File(
        options: ZBScoreS3FileOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func exportS3File(
        fileId: String,
        exportBucket: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func emailFinderS3File(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func domainSearchS3File(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func validateSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func scoreSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func emailFinderSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func domainSearchSFTPFile(
        options: ZBBulkFileJobOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func exportSFTPFile(
        fileId: String,
        exportPath: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getInboxPlacementProviders(completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getInboxPlacementTestTypes(completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func createInboxPlacementTest(
        name: String,
        options: ZBCreateInboxPlacementTestOptions?,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getInboxPlacementTest(testId: String, completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func listInboxPlacementTests(
        options: ZBListInboxPlacementTestsOptions?,
        completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func deleteInboxPlacementTest(testId: String, completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getInboxPlacementWebhook(completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func setInboxPlacementWebhook(webhookUrl: String, completion: @escaping (ZeroBounceSDK.ZBDictionaryResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func listS3files(
        bucket: String?,
        search: String?,
        completion: @escaping (ZeroBounceSDK.ZBResult<[ZBS3ListFileEntry]>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func fileStatus(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBFileStatusResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func scoringFileStatus(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBFileStatusResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func deleteFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBDeleteFileResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func scoringDeleteFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBDeleteFileResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

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
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

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
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func scoringSendFile(
        filePath: String,
        emailAddressColumn: Int,
        returnUrl: String?,
        hasHeaderRow: Bool,
        removeDuplicate: Bool?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func scoringSendFile(
        fileData: Data,
        fileName: String,
        emailAddressColumn: Int,
        returnUrl: String?,
        hasHeaderRow: Bool,
        removeDuplicate: Bool?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBSendFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getFile(
        fileId: String,
        options: ZBGetFileOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getFileStreaming(
        fileId: String,
        downloadPath: String,
        options: ZBGetFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func scoringGetFileStreaming(
        fileId: String,
        downloadPath: String,
        options: ZBGetFileOptions?,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func scoringGetFile(fileId: String, completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func scoringGetFile(
        fileId: String,
        options: ZBGetFileOptions,
        completion: @escaping (ZeroBounceSDK.ZBResult<ZBGetFileResponse>) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }
}

private final class FakeZeroBounceWarmup: ZeroBounceWarmupProtocol {
    private(set) var calls: [String] = []
    private(set) var addedWithOptions: [Bool] = []
    var listSendingAccountsResult: ZeroBounceWarmup.ZBWarmupResult?

    private func record(_ call: String) { calls.append(call) }

    func listSendingAccounts(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(listSendingAccountsResult ?? .Failure(FakeError.notStubbed))
    }

    func getSendingAccount(fromAddress: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func addSendingAccount(
        fromAddress: String,
        onboardingModel: String,
        options: ZBWarmupAddSendingAccountOptions?,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    ) {
        record(#function)
        addedWithOptions.append(options != nil)
        completion(.Success(nil))
    }

    func updateSendingAccount(
        fromAddress: String,
        engagementRuleId: Int,
        statusId: Int,
        autoEnable: Bool,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func deleteSendingAccount(fromAddress: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func changeFromAddress(
        oldFromAddress: String,
        newFromAddress: String,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func listFromAddresses(
        options: ZBWarmupListFromAddressesOptions?,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getEngagementRules(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func setEngagementRule(
        cFrom: String,
        ruleId: Int,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getCustomEngagement(cFrom: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func createCustomEngagement(
        cFrom: String,
        replyPct: Int,
        importantPct: Int,
        clickPct: Int,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func updateCustomEngagement(
        cFrom: String,
        replyPct: Int,
        importantPct: Int,
        clickPct: Int,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func deleteCustomEngagement(
        cFrom: String,
        engagementRuleId: Int,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getSeeds(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func downloadSeeds(completion: @escaping (ZeroBounceWarmup.ZBWarmupCsvResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getSeedCount(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getProgressToday(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getSentToday(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getEmailsPerDay(completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getStatistics(fromAddress: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getStatisticsPerDay(
        fromAddress: String,
        startDate: String,
        endDate: String,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getStatisticsDetailed(cFrom: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func downloadStatistics(cFrom: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupCsvResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func getFromAddressStatistics(fromAddress: String, completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func checkDomainDmarc(
        fromAddress: String,
        dkimSelector: String?,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }

    func testSmtpConfiguration(
        fromAddress: String,
        username: String,
        password: String,
        server: String,
        port: Int,
        completion: @escaping (ZeroBounceWarmup.ZBWarmupResult) -> ()
    ) {
        record(#function)
        completion(.Failure(FakeError.notStubbed))
    }
}

final class ClientProtocolFakeTests: XCTestCase {

    private func validResponse() throws -> ZBValidateResponse {
        let json = #"{"address":"someone@example.com","status":"valid","sub_status":"","free_email":false,"mx_found":"true","processed_at":"2026-11-20 10:00:00.000"}"#
        return try JSONDecoder().decode(ZBValidateResponse.self, from: Data(json.utf8))
    }

    func testAppCodeTakesAFakeSDK() throws {
        let fake = FakeZeroBounceSDK()
        fake.validateResult = .Success(try validResponse())
        let gate = SignupGate(client: fake)

        var accepted: Bool?
        gate.accepts("someone@example.com") { accepted = $0 }

        XCTAssertEqual(accepted, true)
        XCTAssertEqual(fake.calls, ["validate(email:ipAddress:completion:)"])
        // The convenience overload passes the class's default for ipAddress.
        XCTAssertEqual(fake.validated.count, 1)
        XCTAssertEqual(fake.validated.first?.email, "someone@example.com")
        XCTAssertNil(fake.validated.first?.ipAddress ?? nil)

        fake.validateResult = .Failure(FakeError.notStubbed)
        gate.accepts("someone@example.com") { accepted = $0 }
        XCTAssertEqual(accepted, false)
    }

    func testUnstubbedCallsOnTheFakeFail() {
        let client: any ZeroBounceSDKProtocol = FakeZeroBounceSDK()
        var failed = false
        client.getCredits { if case .Failure = $0 { failed = true } }
        XCTAssertTrue(failed)
        client.listS3files { if case .Failure = $0 { failed = true } }
        XCTAssertEqual((client as? FakeZeroBounceSDK)?.calls,
                       ["getCredits(completion:)", "listS3files(bucket:search:completion:)"])
    }

    func testAppCodeTakesAFakeWarmup() {
        let fake = FakeZeroBounceWarmup()
        fake.listSendingAccountsResult = .Success([["from_address": "a@example.com"], ["from_address": "b@example.com"]])
        var count: Int?
        WarmupDashboard(client: fake).accountCount { count = $0 }
        XCTAssertEqual(count, 2)

        let client: any ZeroBounceWarmupProtocol = fake
        client.addSendingAccount(fromAddress: "a@example.com", onboardingModel: ZeroBounceWarmup.selfManaged) { _ in }
        XCTAssertEqual(fake.addedWithOptions, [false])
        XCTAssertEqual(fake.calls, ["listSendingAccounts(completion:)",
                                    "addSendingAccount(fromAddress:onboardingModel:options:completion:)"])
    }

    /// The real clients are the protocols' main conformers.
    func testTheClientsConform() {
        let sdk: any ZeroBounceSDKProtocol = ZeroBounceSDK.shared
        let warmup: any ZeroBounceWarmupProtocol = ZeroBounceWarmup.shared
        XCTAssertTrue(sdk is ZeroBounceSDK)
        XCTAssertTrue(warmup is ZeroBounceWarmup)
    }
}
