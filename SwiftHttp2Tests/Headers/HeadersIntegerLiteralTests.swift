//
//  HeadersIntegerLiteralTests.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/6/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2

class HeadersIntegerLiteralTests: XCTestCase {
    // https://tools.ietf.org/html/rfc7541#appendix-C.1.1
    func test_encode_10_prefix_5() {
        let encoded = Http2HeaderEncoder().encode(10, prefixBits: 5)

        XCTAssertEqual([10], encoded)
    }

    // https://tools.ietf.org/html/rfc7541#appendix-C.1.2
    func test_encode_1337_prefix_5() {
        let encoded = Http2HeaderEncoder().encode(1337, prefixBits: 5)

        XCTAssertEqual(encoded, [31, 154, 10])
    }

    // https://tools.ietf.org/html/rfc7541#appendix-C.1.3
    func test_encode_42_at_octet_boundary() {
        let encoded = Http2HeaderEncoder().encode(42, prefixBits: 8)
        XCTAssertEqual([42], encoded)
    }
}
