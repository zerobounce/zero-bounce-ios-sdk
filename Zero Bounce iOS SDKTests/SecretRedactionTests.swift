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

    func testMarksInEitherOrderFoldToTheSameSpelling() {
        // "i" plus a dot below plus a dot above, and the other order.
        let key = "ki\u{323}\u{307}-key9"
        let other = "ki\u{307}\u{323}-key9"
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad \(other) here"), "bad *** here")
        XCTAssertEqual(ZeroBounceSDK.redacting([other], in: "bad \(key) here"), "bad *** here")
        XCTAssertTrue(ZeroBounceSDK.revealsSecret(other, [key]))
        XCTAssertTrue(ZeroBounceSDK.revealsSecret(key, [other]))
        // "ị" (U+1ECB) plus a dot above against "i", the dot above, the dot below.
        let precomposed = "k\u{1ECB}\u{307}-key9"
        XCTAssertEqual(ZeroBounceSDK.redacting([precomposed], in: "bad \(other) here"), "bad *** here")
        XCTAssertEqual(ZeroBounceSDK.redacting([other], in: "bad \(precomposed) here"), "bad *** here")
        XCTAssertEqual(ZeroBounceSDK.redacting([precomposed], in: "bad \(key) here"), "bad *** here")
        // Capitals too.
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad KI\u{307}\u{323}-KEY9 here"), "bad *** here")
    }

    func testMarksInADifferentOrderDoNotMaskOtherText() {
        XCTAssertEqual(ZeroBounceSDK.redacting(["ki\u{323}\u{307}-key9"], in: "ki-key9"), "ki-key9")
        XCTAssertEqual(ZeroBounceSDK.redacting(["ki\u{323}\u{307}-key9"], in: "ki\u{323}-key9"), "ki\u{323}-key9")
    }

    func testAGreekYpogegrammeniPlusAnAccentMatchesItsPrecomposedFormBothWays() {
        // "ᾀ" (U+1F80) plus an acute accent, against the precomposed "ᾄ" (U+1F84).
        let decomposedMarks = "k\u{1F80}\u{301}-key9"
        let precomposed = "k\u{1F84}-key9"
        let jamoStyle = "k\u{3B1}\u{313}\u{301}\u{345}-key9"
        for (secret, echo) in [(decomposedMarks, precomposed), (precomposed, decomposedMarks),
                               (decomposedMarks, jamoStyle), (jamoStyle, precomposed), (precomposed, jamoStyle)] {
            XCTAssertEqual(ZeroBounceSDK.redacting([secret], in: "bad \(echo) here"), "bad *** here")
            XCTAssertTrue(ZeroBounceSDK.revealsSecret(echo, [secret]))
        }
        XCTAssertEqual(ZeroBounceSDK.redacting([decomposedMarks], in: "bad \(precomposed.uppercased()) here"), "bad *** here")
        // Another letter is another key.
        XCTAssertEqual(ZeroBounceSDK.redacting([decomposedMarks], in: "k\u{1F85}-key9"), "k\u{1F85}-key9")
    }

    func testASecretThatStartsWithTheDotAboveIsMaskedWhereTheTextPutsItOnAnI() {
        let key = "\u{307}key99"
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad xi\u{307}key99 here"), "bad x*** here")
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("i\u{307}key99", [key]))
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("\u{130}KEY99", [key]))
        // Still found where the mark has any other base.
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad x\u{307}key99 here"), "bad *** here")
        // Not found without the mark, and a plain "i" is not a dot.
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad ikey99 here"), "bad ikey99 here")
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad key99 here"), "bad key99 here")
    }

    func testASecretThatEndsInADotAboveIsMaskedWhereTheTextContinuesWithADotBelow() {
        let key = "key99a\u{307}"
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad key99a\u{307}\u{323} here"), "bad *** here")
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad key99a\u{323}\u{307} here"), "bad *** here")
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("key99a\u{323}\u{307}", [key]))
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("KEY99A\u{307}\u{323}", [key]))
        // The mark is still required.
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad key99a\u{323} here"), "bad key99a\u{323} here")
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad key99a here"), "bad key99a here")
    }

    func testADotBelowAndAboveOnAnIDoesNotMaskAnIWithADotBelow() {
        XCTAssertEqual(ZeroBounceSDK.redacting(["ki\u{323}\u{307}-key9"], in: "ki\u{323}-key9"), "ki\u{323}-key9")
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ki\u{323}-key9", ["ki\u{323}\u{307}-key9"]))
        // A text with the marks in the other order is the same spelling.
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("ki\u{307}\u{323}-key9", ["ki\u{323}\u{307}-key9"]))
    }

    func testALocaleCasingOfTheDottedCapitalIWithABelowMarkIsNotMasked() {
        // "İ" plus a dot below is "i", the dot below and the dot above under the
        // default fold; a Turkish or Lithuanian casing is no such spelling.
        XCTAssertEqual(ZeroBounceSDK.redacting(["k\u{130}\u{323}-key9"], in: "ki\u{323}-key9"), "ki\u{323}-key9")
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ki\u{323}-key9", ["k\u{130}\u{323}-key9"]))
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

    func testAHexEscapeOfAQuoteIsDecoded() {
        let key = "ab'xy12"
        for spelling in ["\\x27", "\\X27"] {
            let text = "Invalid key ab\(spelling)xy12 for this account"
            XCTAssertTrue(ZeroBounceSDK.revealsSecret(text, [key]), spelling)
            let cleaned = ZeroBounceSDK.redacting([key], in: text)
            XCTAssertNotEqual(cleaned, text, spelling)
            XCTAssertFalse(cleaned.contains("xy12"), spelling)
            XCTAssertFalse(ZeroBounceSDK.revealsSecret(cleaned, [key]), spelling)
        }
        // Exactly two hex digits: one digit, or a non-hex digit, is no escape.
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab\\x2xy12", [key]))
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab\\xg7xy12", [key]))
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab\\x", [key]))
        // Two digits, then whatever follows stays; a letter-case hex works too.
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("AB\\x27XY12", ["ab'xy12"]))
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("k=a\\x2fb", ["a/b"]))
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("k=a\\x2Fb", ["a/b"]))
    }

    func testAnEscapedQuoteIsDecoded() {
        let key = "ab'xy12"
        let text = "Invalid key ab\\'xy12 for this account"
        XCTAssertTrue(ZeroBounceSDK.revealsSecret(text, [key]))
        let cleaned = ZeroBounceSDK.redacting([key], in: text)
        XCTAssertNotEqual(cleaned, text)
        XCTAssertFalse(cleaned.contains("xy12"))
        XCTAssertFalse(ZeroBounceSDK.revealsSecret(cleaned, [key]))
        // A backslash that is escaped itself is not a quote escape.
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab\\\\xy12", [key]))
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

    func testAKeyWithTheOtherMongolianSeparatorsIsRefusedAnywhere() {
        for scalar in ["\u{180C}", "\u{180D}", "\u{180E}", "\u{180F}"] {
            XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("ab\(scalar)cd"), scalar.unicodeScalars.first!.description)
            XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("\(scalar)abcd"), scalar.unicodeScalars.first!.description)
            XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("abcd\(scalar)"), scalar.unicodeScalars.first!.description)
        }
    }

    func testAKeyWithAUnicodeSpaceInTheMiddleIsRefused() {
        var spaces: [Unicode.Scalar] = [Unicode.Scalar(0x1680)!, Unicode.Scalar(0x2029)!,
                                        Unicode.Scalar(0x202F)!, Unicode.Scalar(0x205F)!]
        spaces += (0x2000...0x200A).map { Unicode.Scalar($0)! }
        for scalar in spaces {
            XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("ab\(scalar)cd"), String(scalar.value, radix: 16))
        }
    }

    func testAnOrdinarySpaceInTheMiddleOfAKeyStaysAllowed() {
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("ab cd"))
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("a b c d"))
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("ab\u{B7}cd"))
        XCTAssertTrue(ZeroBounceSDK().initialize(apiKey: "ab cd"))
        XCTAssertTrue(ZeroBounceWarmup().initialize(apiKey: "ab cd"))
    }

    func testAKeyOfCombiningMarksAloneIsRefused() {
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("\u{301}"))
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("\u{301}\u{302}\u{20DD}"))
    }

    func testAKeyThatPassedTheOldCheckStillPasses() {
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey(""))
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("0123456789abcdef0123456789abcdef"))
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("ab cd"))
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("ab\u{B7}cd"))
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("e\u{301}"))
        XCTAssertTrue(ZeroBounceSDK.isCleanApiKey("\u{4D9}key"))
        // The ends and the control characters are still refused.
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey(" abcd"))
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("abcd\n"))
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("ab\u{0}cd"))
        XCTAssertFalse(ZeroBounceSDK.isCleanApiKey("\u{A0}abcd"))
    }

    func testBothClientsRefuseTheKeysAndLeaveThemselvesUninitialized() {
        let bad = ["ab\u{A0}cd", "ab\u{2028}cd", "ab\u{3000}cd", "ab\u{180B}cd", "\u{301}",
                   "ab\u{180C}cd", "ab\u{180D}cd", "ab\u{180F}cd", "ab\u{2000}cd", "ab\u{200A}cd",
                   "ab\u{2029}cd", "ab\u{202F}cd", "ab\u{205F}cd", "ab\u{1680}cd"]
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

    // MARK: Redaction and error text (fixer J)

    /// What a masked error text may never hold: the key, in any case.
    private func assertNoLeak(_ text: String, _ key: String, _ note: String = "", file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(text.lowercased().contains(key.lowercased()), "leak: \(note) \(text.prefix(200))", file: file, line: line)
        XCTAssertFalse(ZeroBounceSDK.revealsSecret(text, [key]), "reveals: \(note)", file: file, line: line)
    }

    func testAnHtmlTitleIsFoundOnTheOriginalTextWhateverLowercasingDoesToIt() {
        let key = "zb-dummy-key-ABCDEFGH12345678abcd"
        let paddings = ["", "\u{130}", String(repeating: "\u{130}", count: 50), "\u{212A}",
                        String(repeating: "\u{212A}", count: 4), "\u{DF}", "e\u{301}\u{323}",
                        String(repeating: "\u{130}\u{212A}\u{DF}e\u{301}", count: 40)]
        let shapes: [(String) -> String] = [
            { "<html><head><title>\($0)</title></head></html>" },
            { "<html><head><TITLE>\($0)</TITLE></head></html>" },
            { "<html><head><TiTlE id=\"a\" class='b'>\($0)</tItLe></head></html>" },
            { "<html><head><title>\($0)" },
            { "<html><head><title \($0)" },
            { "<html><head><title>" + $0 + "</title" },
        ]
        for before in paddings {
            for inside in paddings {
                for after in paddings {
                    for shape in shapes {
                        let body = before + shape(inside + key + inside) + after
                        let message = ZBError.message(from: Data(body.utf8), statusCode: 502)
                        assertNoLeak(ZeroBounceSDK.redacting([key], in: message), key)
                    }
                }
            }
        }
    }

    func testAnHtmlTitleKeepsItsTextAndTheKeyInItIsMaskedWhole() {
        let key = "zb-dummy-key-ABCDEFGH12345678abcd"
        let body = String(repeating: "\u{130}", count: 4) + "<html><head><title> Bad key \(key) </title></head></html>"
        let message = ZBError.message(from: Data(body.utf8), statusCode: 502)
        XCTAssertEqual(message, "ZeroBounce returned an HTML error page (\"Bad key \(key)\") instead of an API response.")
        XCTAssertEqual(ZeroBounceSDK.redacting([key], in: message),
                       "ZeroBounce returned an HTML error page (\"Bad key ***\") instead of an API response.")
        XCTAssertEqual(ZBError.message(from: Data("<html><TITLE>Oops</TITLE></html>".utf8), statusCode: 502),
                       "ZeroBounce returned an HTML error page (\"Oops\") instead of an API response.")
        XCTAssertEqual(ZBError.message(from: Data("<html><title>Oops".utf8), statusCode: 502),
                       "ZeroBounce returned an HTML error page instead of an API response.")
    }

    func testByteEscapesAreUtf8BytesAndANonAsciiKeyEchoedThatWayIsMasked() {
        let key = "ab\u{E9}cd\u{65E5}\u{672C}k9"
        let spellings = ["ab\\xc3\\xa9cd\\xe6\\x97\\xa5\\xe6\\x9c\\xack9", "ab\\xC3\\xA9cd\\xE6\\x97\\xA5\\xE6\\x9C\\xACk9",
                         "ab\\303\\251cd\\346\\227\\245\\346\\234\\254k9"]
        for spelling in spellings {
            XCTAssertTrue(ZeroBounceSDK.revealsSecret(spelling, [key]), spelling)
            XCTAssertEqual(ZeroBounceSDK.redacting([key], in: "bad key: \(spelling)!"),
                           ZeroBounceSDK.secretOmittedMessage, spelling)
            // Layered: percent-encoded, JSON-escaped, HTML-escaped on top.
            let encoded = spelling.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            XCTAssertTrue(ZeroBounceSDK.revealsSecret(encoded, [key]), encoded)
            XCTAssertTrue(ZeroBounceSDK.revealsSecret(spelling.replacingOccurrences(of: "\\", with: "\\\\"), [key]))
            XCTAssertTrue(ZeroBounceSDK.revealsSecret(spelling.replacingOccurrences(of: "\\", with: "&#92;"), [key]))
        }
        // A lone byte that starts no valid sequence is read as Latin-1 too.
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("ab\\xe9cd\\xff", ["ab\u{E9}cd"]))
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab\\xc3cd", ["ab\u{E9}cd"]))
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab\\xc3\\x28cd", ["ab\u{E9}cd"]))
        // Plain ASCII escapes are as before.
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("ab\\x27xy12", ["ab'xy12"]))
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("ab\\047xy12", ["ab'xy12"]))
    }

    func testAKeyWithAnInvisibleOrFillerCharacterIsRefusedByBothClients() {
        let bad: [UInt32] = [0x3164, 0x115F, 0x1160, 0xFFA0, 0x2800, 0xFFFD, 0x34F, 0x17B4, 0xFE0F, 0x200B, 0x200D, 0xAD,
                             0x2060, 0xFEFF, 0xE0001]
        let sdk = ZeroBounceSDK()
        let warmup = ZeroBounceWarmup()
        for code in bad {
            let scalar = String(Unicode.Scalar(code)!)
            for key in ["ab\(scalar)cd", "\(scalar)abcd", "abcd\(scalar)"] {
                XCTAssertFalse(ZeroBounceSDK.isCleanApiKey(key), String(code, radix: 16))
            }
            XCTAssertFalse(sdk.initialize(apiKey: "ab\(scalar)cd"), String(code, radix: 16))
            XCTAssertNil(sdk.apiKey)
            XCTAssertFalse(warmup.initialize(apiKey: "ab\(scalar)cd"), String(code, radix: 16))
            XCTAssertNil(warmup.apiKey)
        }
    }

    func testAnAdversarialNonAsciiBodyIsMaskedInAFewSeconds() {
        let secrets = ["k1-\u{130}\u{DF}-aaaaaaaa", "k2-\u{212A}-bbbbbbbb", "k3-\u{E9}-cccccccc"]
        let filler = String(repeating: "\u{130}\u{DF}e\u{301}\u{4E2D}%2B\\u00e9&amp;", count: 2_000_000 / 18)
        let body = "{\"message\":\"\(filler)\"}"
        let started = Date()
        let message = ZBError.message(from: Data(body.utf8), statusCode: 500)
        let cleaned = ZeroBounceSDK.redacting(secrets, in: message)
        let direct = ZeroBounceSDK.redacting(secrets, in: body)
        XCTAssertEqual(message, "ZeroBounce returned a JSON error response that is too long to show.")
        XCTAssertEqual(cleaned, message)
        XCTAssertEqual(direct, ZeroBounceSDK.tooLongToShowMessage)
        // The error path takes the same way.
        _ = ZeroBounceSDK.redacting(secrets, in: ZBError.httpError(message: body, statusCode: 500))
        XCTAssertLessThan(Date().timeIntervalSince(started), 5)
    }

    func testAMessageFieldOverAThousandCharactersIsTheFixedText() {
        let fixed = "ZeroBounce returned a JSON error response that is too long to show."
        let ok = String(repeating: "\u{E9}", count: 1000)
        let long = String(repeating: "\u{E9}", count: 1001)
        XCTAssertEqual(ZBError.message(from: Data("{\"message\":\"\(ok)\"}".utf8), statusCode: 500), ok)
        XCTAssertEqual(ZBError.message(from: Data("{\"message\":\"\(long)\"}".utf8), statusCode: 500), fixed)
        XCTAssertEqual(ZBError.message(from: Data("{\"x_error\":\"\(long)\"}".utf8), statusCode: 500), fixed)
        let only = ZBError.messageOnlyFailure(Data("{\"message\":\"\(long)\"}".utf8), statusCode: 200)
        guard case .httpError(let text, 200)? = only else { return XCTFail("\(String(describing: only))") }
        XCTAssertEqual(text, fixed)
    }

    func testALongJsonErrorWithNoMessageKeyIsTheFixedText() {
        let fixed = "ZeroBounce returned a JSON error response that is too long to show."
        // 5000 characters: over the limit, far under 100000.
        let body = "{\"pad\":\"\(String(repeating: "x", count: 5000))\"}"
        XCTAssertEqual(ZBError.message(from: Data(body.utf8), statusCode: 500), fixed)
        let short = "{\"pad\":\"\(String(repeating: "x", count: 900))\"}"
        XCTAssertEqual(ZBError.message(from: Data(short.utf8), statusCode: 500), short)
    }

    func testDuplicateSuccessKeysWithARealFalseAreAFailure() {
        func failure(_ json: String) -> Bool { ZBError.successMeansFailure(Data(json.utf8)) }
        XCTAssertTrue(failure("{\"success\":true,\"success\":false}"))
        XCTAssertTrue(failure("{\"success\":false,\"success\":true}"))
        XCTAssertTrue(failure("{\"a\":{\"success\":true},\"success\":true,\"succ\\u0065ss\":\"false\"}"))
        XCTAssertTrue(failure("{\"success\":true, \"success\": 0}"))
        XCTAssertFalse(failure("{\"success\":true,\"success\":true}"))
        XCTAssertFalse(failure("{\"success\":true,\"success\":null}"))
        XCTAssertFalse(failure("{\"a\":{\"success\":false},\"success\":true}"))
        XCTAssertFalse(failure("{\"success\":true}"))
    }

    func testATransportErrorCarryingTheKeyInItsUserInfoIsScrubbedEverywhere() {
        let key = "zb-dummy-key-ABCDEFGH12345678abcd"
        let url = URL(string: "https://api.zerobounce.net/v2/validate?api_key=\(key)&email=a@b.c")!
        let inner = URLError(.cannotConnectToHost, userInfo: [
            NSURLErrorFailingURLErrorKey: url, NSURLErrorFailingURLStringErrorKey: url.absoluteString,
        ])
        let error = URLError(.timedOut, userInfo: [
            NSURLErrorFailingURLErrorKey: url,
            NSURLErrorFailingURLStringErrorKey: url.absoluteString,
            NSUnderlyingErrorKey: inner,
            "dict": ["list": [url.absoluteString, ["deep": Data(url.absoluteString.utf8)]]] as [String: Any],
            "data": Data("GET \(url.absoluteString)".utf8),
            "any": [AnyHashable("k"): url.absoluteString] as [AnyHashable: Any],
        ])
        let cleaned = ZeroBounceSDK.redactingApiKey(key, in: error)
        XCTAssertEqual((cleaned as? URLError)?.code, .timedOut)
        let ns = cleaned as NSError
        func walk(_ value: Any) {
            switch value {
            case let text as String: assertNoLeak(text, key)
            case let url as URL: assertNoLeak(url.absoluteString, key)
            case let data as Data: assertNoLeak(String(decoding: data, as: UTF8.self), key)
            case let nested as NSError: nested.userInfo.values.forEach(walk)
            case let list as [Any]: list.forEach(walk)
            case let map as [String: Any]: map.values.forEach(walk)
            case let map as [AnyHashable: Any]: map.values.forEach(walk)
            default: break
            }
        }
        ns.userInfo.values.forEach(walk)
        XCTAssertNotNil(ns.userInfo[NSURLErrorFailingURLStringErrorKey] as? String)
        XCTAssertTrue((ns.userInfo[NSURLErrorFailingURLStringErrorKey] as? String)?.contains("api_key=***") == true)
        XCTAssertNotNil(ns.userInfo["data"] as? Data)
        assertNoLeak(String(describing: ns.userInfo), key)
        assertNoLeak(String(describing: cleaned), key)
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

    // MARK: Audit 2

    func testALatin1ByteEscapeOfANonAsciiSecretIsRevealed() {
        let key = "ab\u{E9}cd12"
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("ab\\xe9cd12", [key]))
        XCTAssertTrue(ZeroBounceSDK.revealsSecret("ab\\351cd12", [key]))
        XCTAssertFalse(ZeroBounceSDK.revealsSecret("ab\\xe8cd12", [key]))
    }

    func testUserInfoKeysSetsAttributedStringsComponentsAndRequestsAreScrubbed() throws {
        let key = "SECRET-KEY-77"
        var request = URLRequest(url: URL(string: "https://api.example/v2/x?api_key=\(key)")!)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let components = URLComponents(string: "https://api.example/v2/x?api_key=\(key)")!
        let info: [String: Any] = [
            "key-\(key)": "x",
            "set": Set(["a", "b-\(key)"]),
            "attributed": NSAttributedString(string: "oops \(key)"),
            "components": components,
            "request": request,
            "nsrequest": NSURLRequest(url: URL(string: "https://api.example/?k=\(key)")!),
            "opaque": NSObject(),
            "number": 7,
        ]
        let error = NSError(domain: "d", code: 1, userInfo: info)
        let cleaned = ZeroBounceSDK.redacting([key], in: error) as NSError
        let text = String(describing: cleaned.userInfo)
        XCTAssertFalse(text.contains(key), text)
        XCTAssertEqual(cleaned.userInfo["number"] as? Int, 7)
        XCTAssertEqual(cleaned.userInfo["opaque"] as? String, ZeroBounceSDK.omittedValue)
        let scrubbed = cleaned.userInfo["request"] as? URLRequest
        XCTAssertEqual(scrubbed?.value(forHTTPHeaderField: "Authorization"), "Bearer ***")
    }

    func testASelfContainingUserInfoDoesNotCrash() {
        let key = "SECRET-KEY-78"
        let loop = NSMutableDictionary()
        loop["self"] = loop
        loop["text"] = "has \(key)"
        let error = NSError(domain: "d", code: 1, userInfo: ["loop": loop])
        let cleaned = ZeroBounceSDK.redacting([key], in: error) as NSError
        XCTAssertFalse(String(describing: cleaned.userInfo).contains(key))
        // And a chain nested far deeper than the limit.
        var nested: Any = "deep \(key)"
        for _ in 0..<500 { nested = ["next": nested] }
        let deep = ZeroBounceSDK.redacting([key], in: NSError(domain: "d", code: 2, userInfo: ["n": nested])) as NSError
        XCTAssertFalse(String(describing: deep.userInfo).contains(key))
    }
}
