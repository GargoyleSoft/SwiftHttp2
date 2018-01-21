//
//  HeadersStringLiteralTests.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/6/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2

class HeadersLiteralOctetsTests: XCTestCase {
    // http://tools.ietf.org/html/rfc7541#appendix-C.2.1
    func testLiteralHeaderWithIndexing() {
        let encoded = Http2HeaderEncoder.encode(headers: [Http2HeaderEntry(field: "custom-key", value: "custom-header")], indexing: .literalHeaderIncremental, using: .literalOctets)
        XCTAssertEqual(encoded, [0x40, 0x0a, 0x63, 0x75, 0x73, 0x74, 0x6f, 0x6d, 0x2d,
                                 0x6b, 0x65, 0x79, 0x0d, 0x63, 0x75, 0x73, 0x74, 0x6f,
                                 0x6d, 0x2d, 0x68, 0x65, 0x61, 0x64, 0x65, 0x72
            ])
    }

    // http://tools.ietf.org/html/rfc7541#appendix-C.2.2
    func test_literal_header_without_indexing() {
        let encoded = Http2HeaderEncoder.encode(field: ":path", value: "/sample/path", using: .literalOctets)
        XCTAssertEqual(encoded, [0x04, 0x0c, 0x2f, 0x73, 0x61, 0x6d, 0x70, 0x6c, 0x65, 0x2f, 0x70, 0x61, 0x74, 0x68])
    }

    // http://tools.ietf.org/html/rfc7541#appendix-C.2.3
    func test_literal_header_never_indexing() {
        let encoded = Http2HeaderEncoder.encode(field: "password", value: "secret", indexing: .literalHeaderNever, using: .literalOctets)
        XCTAssertEqual(encoded, [0x10, 0x08, 0x70, 0x61, 0x73, 0x73, 0x77, 0x6f, 0x72, 0x64, 0x06, 0x73, 0x65, 0x63, 0x72, 0x65, 0x74])
    }

    // http://tools.ietf.org/html/rfc7541#appendix-C.2.4
    func test_indexed_header_field() {
        let encoded = Http2HeaderEncoder.encode(field: ":method", value: "GET")
        XCTAssertEqual(encoded, [0x82])
    }

    func test_indexed_header_field_ignores_indexing() {
        let encoder = Http2HeaderEncoder()
        let incr = encoder.encode(field: ":method", value: "GET", indexing: .literalHeaderIncremental)
        let none = encoder.encode(field: ":method", value: "GET", indexing: .none)
        let never = encoder.encode(field: ":method", value: "GET", indexing: .literalHeaderNever)

        XCTAssertEqual(incr, none)
        XCTAssertEqual(none, never)
    }

    func test_consecutive_header_lists() {
        let encoder = Http2HeaderEncoder(stringEncoding: .literalOctets)

        var headers: [Http2HeaderEntry] = [
            Http2HeaderEntry(field: ":method", value: "GET"),
            Http2HeaderEntry(field: ":scheme", value: "http"),
            Http2HeaderEntry(field: ":path", value: "/"),
            Http2HeaderEntry(field: ":authority", value: "www.example.com")
        ]

        // http://tools.ietf.org/html/rfc7541#appendix-C.3.1
        var encoded = encoder.encode(headers: headers, indexing: .literalHeaderIncremental)
        XCTAssertEqual(encoded, [
            0x82, 0x86, 0x84, 0x41, 0x0f, 0x77, 0x77, 0x77, 0x2e, 0x65, 0x78,
            0x61, 0x6d, 0x70, 0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d
            ])
        XCTAssertEqual(encoder.headerTable.dynamicTable.count, 1)

        // http://tools.ietf.org/html/rfc7541#appendix-C.3.2
        headers.append(Http2HeaderEntry(field: "cache-control", value: "no-cache"))

        encoded = encoder.encode(headers: headers, indexing: .literalHeaderIncremental)
        XCTAssertEqual(encoded, [
            0x82, 0x86, 0x84, 0xbe, 0x58, 0x08, 0x6e, 0x6f, 0x2d, 0x63, 0x61, 0x63, 0x68, 0x65
            ])
        XCTAssertEqual(encoder.headerTable.dynamicTable.count, 2)
        print(encoder.headerTable.dumpTableForUnitTests())

        // http://tools.ietf.org/html/rfc7541#appendix-C.3.3
        headers = [
            Http2HeaderEntry(field: ":method", value: "GET"),
            Http2HeaderEntry(field: ":scheme", value: "https"),
            Http2HeaderEntry(field: ":path", value: "/index.html"),
            Http2HeaderEntry(field: ":authority", value: "www.example.com"),
            Http2HeaderEntry(field: "custom-key", value: "custom-value")
        ]

        encoded = encoder.encode(headers: headers, indexing: .literalHeaderIncremental)
        XCTAssertEqual(encoded, [
            0x82, 0x87, 0x85, 0xbf, 0x40, 0x0a, 0x63, 0x75, 0x73, 0x74, 0x6f, 0x6d, 0x2d, 0x6b, 0x65, 0x79,
            0x0c, 0x63, 0x75, 0x73, 0x74, 0x6f, 0x6d, 0x2d, 0x76, 0x61, 0x6c, 0x75, 0x65
            ])
        XCTAssertEqual(encoder.headerTable.dynamicTable.count, 3)
        print(encoder.headerTable.dumpTableForUnitTests())
    }

    func testWithEvictions() {
        let encoder = Http2HeaderEncoder(stringEncoding: .literalOctets)
        encoder.headerTable.settingsHeaderTableSize = 256

        var headers: [Http2HeaderEntry] = [
            Http2HeaderEntry(field: ":status", value: "302"),
            Http2HeaderEntry(field: "cache-control", value: "private"),
            Http2HeaderEntry(field: "date", value: "Mon, 21 Oct 2013 20:13:21 GMT"),
            Http2HeaderEntry(field: "location", value: "https://www.example.com")
        ]

        // http://tools.ietf.org/html/rfc7541#appendix-C.5.1
        var encoded = encoder.encode(headers: headers, indexing: .literalHeaderIncremental)
        XCTAssertEqual(encoded, [
            0x48, 0x03, 0x33, 0x30, 0x32, 0x58, 0x07, 0x70, 0x72, 0x69, 0x76, 0x61, 0x74, 0x65, 0x61, 0x1d,
            0x4d, 0x6f, 0x6e, 0x2c, 0x20, 0x32, 0x31, 0x20, 0x4f, 0x63, 0x74, 0x20, 0x32, 0x30, 0x31, 0x33,
            0x20, 0x32, 0x30, 0x3a, 0x31, 0x33, 0x3a, 0x32, 0x31, 0x20, 0x47, 0x4d, 0x54, 0x6e, 0x17, 0x68,
            0x74, 0x74, 0x70, 0x73, 0x3a, 0x2f, 0x2f, 0x77, 0x77, 0x77, 0x2e, 0x65, 0x78, 0x61, 0x6d, 0x70,
            0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d
            ])
        XCTAssertEqual(encoder.headerTable.dynamicTable.count, 4)

        // https://tools.ietf.org/html/rfc7541#appendix-C.5.2
        headers = [
            Http2HeaderEntry(field: ":status", value: "307"),
            Http2HeaderEntry(field: "cache-control", value: "private"),
            Http2HeaderEntry(field: "date", value: "Mon, 21 Oct 2013 20:13:21 GMT"),
            Http2HeaderEntry(field: "location", value: "https://www.example.com")
        ]
        encoded = encoder.encode(headers: headers, indexing: .literalHeaderIncremental)
        XCTAssertEqual(encoded, [0x48, 0x03, 0x33, 0x30, 0x37, 0xc1, 0xc0, 0xbf])
        XCTAssertEqual(encoder.headerTable.dynamicTable.count, 4)

        // https://tools.ietf.org/html/rfc7541#appendix-C.5.3
        headers = [
            Http2HeaderEntry(field: ":status", value: "200"),
            Http2HeaderEntry(field: "cache-control", value: "private"),
            Http2HeaderEntry(field: "date", value: "Mon, 21 Oct 2013 20:13:22 GMT"),
            Http2HeaderEntry(field: "location", value: "https://www.example.com"),
            Http2HeaderEntry(field: "content-encoding", value: "gzip"),
            Http2HeaderEntry(field: "set-cookie", value: "foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1")
        ]
        encoded = encoder.encode(headers: headers, indexing: .literalHeaderIncremental)
        XCTAssertEqual(encoded, [
            0x88, 0xc1, 0x61, 0x1d, 0x4d, 0x6f, 0x6e, 0x2c, 0x20, 0x32, 0x31, 0x20, 0x4f, 0x63, 0x74, 0x20,
            0x32, 0x30, 0x31, 0x33, 0x20, 0x32, 0x30, 0x3a, 0x31, 0x33, 0x3a, 0x32, 0x32, 0x20, 0x47, 0x4d,
            0x54, 0xc0, 0x5a, 0x04, 0x67, 0x7a, 0x69, 0x70, 0x77, 0x38, 0x66, 0x6f, 0x6f, 0x3d, 0x41, 0x53,
            0x44, 0x4a, 0x4b, 0x48, 0x51, 0x4b, 0x42, 0x5a, 0x58, 0x4f, 0x51, 0x57, 0x45, 0x4f, 0x50, 0x49,
            0x55, 0x41, 0x58, 0x51, 0x57, 0x45, 0x4f, 0x49, 0x55, 0x3b, 0x20, 0x6d, 0x61, 0x78, 0x2d, 0x61,
            0x67, 0x65, 0x3d, 0x33, 0x36, 0x30, 0x30, 0x3b, 0x20, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e,
            0x3d, 0x31,
            ])
        XCTAssertEqual(encoder.headerTable.dynamicTable.count, 3)
        print(encoder.headerTable.dumpTableForUnitTests())
    }
}
