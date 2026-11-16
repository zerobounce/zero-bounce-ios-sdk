//
//  SecretRedactionTests.swift
//  Zero Bounce iOS SDKTests
//
//  Redaction folds both sides, decodes the spellings of a quote, and the key
//  and base URL checks. Nothing here reaches the network.
//

import XCTest
@testable import Zero_Bounce_iOS_SDK

class SecretRedactionTests: XCTestCase {
    // MARK: Folding

    func testAnAsciiKeyEchoedInCapitalsIsMasked() {
        XCTAssertEqual(ZeroBounceSDK.redacting(["AbCdEf123"], in: "bad key ABCDEF123 here"), "bad key *** here")
        XCTAssertEqual(ZeroBounceSDK.redacting(["AbCdEf123"], in: "bad key abcdef123 here"), "bad key *** here")
        XCTAssertEqual(ZeroBounceSDK.redacting(["abcdef123"], in: "bad key AbCdEf123 here"), "bad key *** here")
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("key=ABCDEF123", ["abcdef123"]))
    }

    func testSharpSEchoedAsSSIsMasked() {
        XCTAssertEqual(ZeroBounceSDK.redacting(["stra\u{DF}e-key"], in: "invalid STRASSE-KEY!"), "invalid ***!")
        XCTAssertEqual(ZeroBounceSDK.redacting(["stra\u{DF}e-key"], in: "invalid strasse-key!"), "invalid ***!")
        XCTAssertEqual(ZeroBounceSDK.redacting(["STRASSE-KEY"], in: "invalid stra\u{DF}e-key!"), "invalid ***!")
    }

    func testDottedCapitalIEchoedAsPlainIOrIWithDotIsMasked() {
        let key = "\u{130}-key9"
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad i-key9 here"), "bad *** here")
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad i\u{307}-key9 here"), "bad *** here")
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad I-KEY9 here"), "bad *** here")
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad \u{130}-KEY9 here"), "bad *** here")
        // And the other way round: a plain key echoed with the dotted capital.
        XCTAssertEqual(ZeroBounceSDK.redacting(["i-key9"], in: "bad \u{130}-key9 here"), "bad *** here")
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("i\u{307}-key9", [key]))
    }

    func testSchwaEchoedInCapitalsIsMasked() {
        XCTAssertEqual(ZeroBounceSDK.redacting(["\u{4D9}key77"], in: "bad \u{4D8}KEY77 here"), "bad *** here")
        XCTAssertEqual(ZeroBounceSDK.redacting(["\u{4D8}KEY77"], in: "bad \u{4D9}key77 here"), "bad *** here")
    }

    func testAHangulSyllableEchoedAsJamoStaysMasked() {
        let syllables = "\u{AC00}\u{B098}\u{B2E4}-key"
        let jamo = "\u{1100}\u{1161}\u{1102}\u{1161}\u{1103}\u{1161}-key"
        XCTAssertEqual(ZeroBounceSDK.redacting([syllables], in: "bad \(jamo) here"), "bad *** here")
        XCTAssertEqual(ZeroBounceSDK.redacting([jamo], in: "bad \(syllables) here"), "bad *** here")
        XCTAssertTrue(ZeroBounceSDK.revealsSecret(jamo, [syllables]))
    }

    func testAKeyFollowedByACombiningMarkIsStillMasked() {
        XCTAssertEqual(ZeroBounceSDK.redacting(["abc123"], in: "bad abc123\u{301} here"), "bad *** here")
    }

    func testFoldingDoesNotMaskOtherText() {
        XCTAssertEqual(ZeroBounceSDK.redacting(["abc123"], in: "nothing to hide: ABC124"), "nothing to hide: ABC124")
        XCTAssertEqual(ZeroBounceSDK.redacting(["abc123"], in: ""), "")
        XCTAssertEqual(ZeroBounceSDK.redacting([""], in: "text"), "text")
    }

    func testAnErrorThatQuotesTheKeyInCapitalsKeepsNoPartOfIt() {
        let key = "Secret-Key-1"
        let error = URLError(.timedOut, userInfo: [
            "NSErrorFailingURLStringKey": "https://api.example/v2/getcredits?api_key=SECRET-KEY-1",
            NSLocalizedDescriptionKey: "The request timed out for SECRET-KEY-1."
        ])
        let cleaned = ZeroBounceSDK.redactingApiKey(key, in: error)
        XCTAssertEqual((cleaned as? URLError)?.code, .timedOut)
        let text = "\(cleaned) \((cleaned as NSError).userInfo) \(cleaned.localizedDescription)".lowercased()
        XCTAssertFalse(text.contains("secret-key-1"), text)
        XCTAssertFalse(text.contains("secret"), text)

        let body = ZeroBounceSDK.redactingApiKey(key, in: ZBError.httpError(message: "Invalid key SECRET-KEY-1", statusCode: 401))
        XCTAssertFalse("\(body)".lowercased().contains("secret-key-1"))
        XCTAssertEqual((body as? ZBError)?.statusCode, 401)
    }

    // MARK: Quote spellings

    func testEverySpellingOfAQuoteIsDecodedBeforeSearching() {
        let key = "ab'xy12"
        let spellings = [
            "\\u0027", "\\u{27}", "\\u{0027}", "\\u{000027}", "\\U{27}", "\\U{000027}",
            "\\U0027", "\\U00000027", "\\047",
            "&apos;", "&APOS;", "&Apos;", "&#39;", "&#039;", "&#x27;", "&#X27;", "&#x0027;",
            // The semicolon is missing and the next character is not a digit.
            "&#39", "&#x27"
        ]
        for spelling in spellings {
            let text = "Invalid key ab\(spelling)xy12 for this account"
            XCTAssertTrue(ZeroBounceSDK.revealsSecret(text, [key]), spelling)
            // Masked where the spelling is one the SDK writes itself (`\u0027`),
            // and the whole text omitted where it is not; never left readable.
            let cleaned = ZeroBounceSDK.redacting([key], in: text)
            XCTAssertNotEqual(cleaned, text, spelling)
            XCTAssertFalse(cleaned.contains("xy12"), spelling)
            XCTAssertFalse(ZeroBounceSDK.revealsSecret(cleaned, [key]), spelling)
        }
    }

    func testEightHexDigitsAreOneCodePointOnlyWhenTheyAreValid() {
        // 0027CDEF is not a code point: the escape is its first four digits.
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("ab\\U0027cdef", ["ab'cdef"]))
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("ab\\U00000027cdef", ["ab'cdef"]))
    }

    func testAQuoteSpellingInCapitalsOfTheKeyIsFoundToo() {
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("AB&#39;XY12", ["ab'xy12"]))
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("AB&amp;apos;XY12", ["ab'xy12"]))
    }

    func testOctalNeedsExactlyThreeDigits() {
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab\\47xy12", ["ab'xy12"]))
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab\\08xy12", ["ab'xy12"]))
        // Three digits, then whatever follows stays.
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("ab\\047xy12", ["ab'xy12"]))
    }

    func testAPercentUSpellingStaysUndecoded() {
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab%u0027xy12", ["ab'xy12"]))
        XCTAssertEqual(ZeroBounceSDK.redacting(["ab'xy12"], in: "ab%u0027xy12"), "ab%u0027xy12")
    }

    func testANumericReferenceThatIsNotACharacterIsKept() {
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab&#0;xy12", ["ab'xy12"]))
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab&#x110000;xy12", ["ab'xy12"]))
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab&#xD800;xy12", ["ab'xy12"]))
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab&unknown;xy12", ["ab'xy12"]))
    }

    func testTheOlderEncodingsStillWork() {
        let key = "ab+/xy12"
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "k=ab%2B%2Fxy12"), "k=***")
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "{\"k\":\"ab+\\/xy12\"}"), "{\"k\":\"***\"}")
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("ab\\u002b\\u002fxy12", [key]))
    }

    // MARK: Key check

    func testAKeyWithTheseCharactersInTheMiddleIsRefused() {
        for scalar in ["\u{A0}", "\u{2028}", "\u{3000}"] {
            XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("ab\(scalar)cd"), scalar.unicodeScalars.first!.description)
        }
    }

    func testAKeyWithAMongolianFreeVariationSelectorIsRefusedAnywhere() {
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("ab\u{180B}cd"))
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("\u{180B}abcd"))
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("abcd\u{180B}"))
    }

    func testAKeyOfCombiningMarksAloneIsRefused() {
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("\u{301}"))
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("\u{301}\u{302}\u{20DD}"))
    }

    func testAKeyThatPassedTheOldCheckStillPasses() {
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey(""))
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("0123456789abcdef0123456789abcdef"))
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("ab cd"))
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("ab\u{2003}cd"))
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("e\u{301}"))
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("\u{4D9}key"))
        // The ends and the control characters are still refused.
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey(" abcd"))
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("abcd\n"))
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("ab\u{0}cd"))
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("\u{A0}abcd"))
    }

    func testBothClientsRefuseTheKeysAndLeaveThemselvesUninitialized() {
        let bad = ["ab\u{A0}cd", "ab\u{2028}cd", "ab\u{3000}cd", "ab\u{180B}cd", "\u{301}"]
        let sdk = ZeroBounceSDK()
        let warmup = ZeroBounceWarmup()
        for key in bad {
            XCTAssertTrue(sdk.initialize(apiKey: "good-key"))
            XCTAssertFalse(sdk.initialize(apiKey: key), key)
            XCTAssertNil(sdk.apiKey)

            XCTAssertTrue(warmup.initialize(apiKey: "good-key"))
            XCTAssertFalse(warmup.initialize(apiKey: key), key)
            XCTAssertNil(warmup.apiKey)
        }
    }

    // MARK: Base URL

    func testABaseUrlWithAQueryOrAFragmentIsRefusedWithAFixedValue() {
        for url in ["https://api.example/v2?token=abc", "https://api.example/v2#frag-abc",
                    "https://api.example/v2/?", " https://api.example/#"] {
            let normalized = ZeroBounceSDK.normalizedBaseUrl(url)
            XCTAssertEqual(normalized, ZeroBounceSDK.refusedBaseUrl, url)
            XCTAssertFalse(normalized.contains("example"), normalized)
            XCTAssertFalse(normalized.contains("token"), normalized)
            // It parses, so a URL built on it never traps, and it is not https.
            XCTAssertNotNil(URL(string: normalized))
            XCTAssertFalse(ZeroBounceSDK.isAllowedURL(URL(string: normalized + "/validate")!))
        }
    }

    func testABaseUrlWithoutThemKeepsItsOldNormalizing() {
        XCTAssertEqual(ZeroBounceSDK.normalizedBaseUrl("https://api.example/v2///"), "https://api.example/v2")
        XCTAssertEqual(ZeroBounceSDK.normalizedBaseUrl("  https://api.example/v2/\n"), "https://api.example/v2")
        XCTAssertEqual(ZeroBounceSDK.normalizedBaseUrl("http://127.0.0.1:8080"), "http://127.0.0.1:8080")
    }

    func testTheWarmupBaseUrlRefusesThemAndNoCallQuotesIt() {
        let warmup = ZeroBounceWarmup()
        XCTAssertTrue(warmup.initialize(apiKey: "warm-key"))
        warmup.baseUrl = "https://api.example/p?token=abc"
        XCTAssertEqual(warmup.baseUrl, ZeroBounceSDK.refusedBaseUrl)

        let done = expectation(description: "answered")
        var text = ""
        warmup.getSeeds { result in
            if case .Failure(let error) = result { text = "\(error) \(error.localizedDescription)" }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertFalse(text.isEmpty)
        XCTAssertFalse(text.contains("token"), text)
        XCTAssertFalse(text.contains("example"), text)
        XCTAssertFalse(text.contains("warm-key"), text)

        warmup.baseUrl = "https://api.example/"
        XCTAssertEqual(warmup.baseUrl, "https://api.example")
    }

    func testTheSdkBaseUrlRefusesThemAndNoCallQuotesIt() {
        let sdk = ZeroBounceSDK()
        XCTAssertTrue(sdk.initialize(apiKey: "sdk-key-1"))
        sdk.apiBaseUrl = "https://api.example/v2?token=abc"
        XCTAssertEqual(sdk.apiBaseUrl, ZeroBounceSDK.refusedBaseUrl)

        let done = expectation(description: "answered")
        var text = ""
        sdk.getCredits { result in
            if case .Failure(let error) = result { text = "\(error) \(error.localizedDescription)" }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertFalse(text.isEmpty)
        XCTAssertFalse(text.contains("token"), text)
        XCTAssertFalse(text.contains("example"), text)
        XCTAssertFalse(text.contains("sdk-key-1"), text)
    }

    // MARK: Multipart

    func testAMultipartRequestRefusesAUrlThatDoesNotParse() throws {
        XCTAssertThrowsError(try ZBMultiPartRequest.createFileRequest(
            url: "", parameters: ["api_key": "k"], filePathKey: "file", paths: []
        )) { error in
            guard case ZBError.invalidEndpoint = error else { return XCTFail("\(error)") }
        }
        XCTAssertThrowsError(try ZBMultiPartRequest.createFileRequestWithData(
            url: "", parameters: nil, filePathKey: "file", fileData: Data("a,b\n".utf8), fileName: "a.csv"
        )) { error in
            guard case ZBError.invalidEndpoint = error else { return XCTFail("\(error)") }
        }

        let ok = try ZBMultiPartRequest.createFileRequestWithData(
            url: "https://api.example/v2/sendfile", parameters: nil, filePathKey: "file",
            fileData: Data("a,b\n".utf8), fileName: "a.csv"
        )
        XCTAssertEqual(ok.httpMethod, "POST")
    }
}
