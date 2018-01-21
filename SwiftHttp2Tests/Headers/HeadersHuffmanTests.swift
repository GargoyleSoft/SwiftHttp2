//
//  HeadersHuffmanTests.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/6/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2

class HeadersHuffmanTests: XCTestCase {
    private let multi1Header: [Http2HeaderEntry] = [
        Http2HeaderEntry(field: ":method", value: "GET"),
        Http2HeaderEntry(field: ":scheme", value: "http"),
        Http2HeaderEntry(field: ":path", value: "/"),
        Http2HeaderEntry(field: ":authority", value: "www.example.com")
    ]

    private let multi1Encoding: [UInt8] = [
        0x82, 0x86, 0x84, 0x41, 0x8c, 0xf1, 0xe3, 0xc2, 0xe5,
        0xf2, 0x3a, 0x6b, 0xa0, 0xab, 0x90, 0xf4, 0xff
    ]

    private let multi2Header: [Http2HeaderEntry] = [
        Http2HeaderEntry(field: ":method", value: "GET"),
        Http2HeaderEntry(field: ":scheme", value: "http"),
        Http2HeaderEntry(field: ":path", value: "/"),
        Http2HeaderEntry(field: ":authority", value: "www.example.com"),
        Http2HeaderEntry(field: "cache-control", value: "no-cache")
    ]

    private let multi2Encoding: [UInt8] = [0x82, 0x86, 0x84, 0xbe, 0x58, 0x86, 0xa8, 0xeb, 0x10, 0x64, 0x9c, 0xbf]

    private let multi3Header: [Http2HeaderEntry] = [
        Http2HeaderEntry(field: ":method", value: "GET"),
        Http2HeaderEntry(field: ":scheme", value: "https"),
        Http2HeaderEntry(field: ":path", value: "/index.html"),
        Http2HeaderEntry(field: ":authority", value: "www.example.com"),
        Http2HeaderEntry(field: "custom-key", value:  "custom-value")
    ]

    private let multi3Encoding: [UInt8] = [
        0x82, 0x87, 0x85, 0xbf, 0x40, 0x88, 0x25, 0xa8, 0x49, 0xe9, 0x5b, 0xa9, 0x7d, 0x7f,
        0x89, 0x25, 0xa8, 0x49, 0xe9, 0x5b, 0xb8, 0xe8, 0xb4, 0xbf
    ]

    func headersMatch(lhs: [Http2HeaderEntry], rhs: [Http2HeaderEntry], file: StaticString = #file, line: UInt = #line) {
        guard lhs.count == rhs.count else {
            XCTFail("Length of headers doesn't match", file: file, line: line)
            return
        }

        for (idx, element) in lhs.enumerated() {
            guard element.field == rhs[idx].field && element.value == rhs[idx].value else {
                XCTFail("Headers don't match", file: file, line: line)
                return
            }
        }
    }

    func testMultiEncoding() {
        let encoder = Http2HeaderEncoder(stringEncoding: .huffmanCode)

        // http://tools.ietf.org/html/rfc7541#appendix-C.4.1
        var encoded = encoder.encode(headers: multi1Header, indexing: .literalHeaderIncremental)
        XCTAssertEqual(encoded, multi1Encoding)
        XCTAssertEqual(encoder.headerTable.dynamicTable.count, 1)

        // http://tools.ietf.org/html/rfc7541#appendix-C.4.2
        encoded = encoder.encode(headers: multi2Header, indexing: .literalHeaderIncremental)
        XCTAssertEqual(encoded, multi2Encoding)
        XCTAssertEqual(encoder.headerTable.dynamicTable.count, 2)
        print(encoder.headerTable.dumpTableForUnitTests())

        // http://tools.ietf.org/html/rfc7541#appendix-C.4.3
        encoded = encoder.encode(headers: multi3Header, indexing: .literalHeaderIncremental)
        XCTAssertEqual(encoded, multi3Encoding)
        XCTAssertEqual(encoder.headerTable.dynamicTable.count, 3)
        print(encoder.headerTable.dumpTableForUnitTests())
    }

    func testMultiDecode() {
        let decoder = Http2HeaderDecoder()

        MyAssertNoThrow(try decoder.decode(encoded: multi1Encoding)) {
            headersMatch(lhs: $0, rhs: multi1Header)
            XCTAssertEqual(decoder.headerTable.dynamicTable.count, 1)
        }

        MyAssertNoThrow(try decoder.decode(encoded: multi2Encoding)) {
            headersMatch(lhs: $0, rhs: multi2Header)
            XCTAssertEqual(decoder.headerTable.dynamicTable.count, 2)
        }

        MyAssertNoThrow(try decoder.decode(encoded: multi3Encoding)) {
            headersMatch(lhs: $0, rhs: multi3Header)
            XCTAssertEqual(decoder.headerTable.dynamicTable.count, 3)
        }
    }

    private let eviction1Headers: [Http2HeaderEntry] = [
        Http2HeaderEntry(field: ":status", value: "302"),
        Http2HeaderEntry(field: "cache-control", value: "private"),
        Http2HeaderEntry(field: "date", value: "Mon, 21 Oct 2013 20:13:21 GMT"),
        Http2HeaderEntry(field: "location", value: "https://www.example.com")
    ]

    private let eviction1Encoding: [UInt8] = [
        0x48, 0x82, 0x64, 0x02, 0x58, 0x85, 0xae, 0xc3, 0x77, 0x1a, 0x4b, 0x61, 0x96, 0xd0, 0x7a, 0xbe,
        0x94, 0x10, 0x54, 0xd4, 0x44, 0xa8, 0x20, 0x05, 0x95, 0x04, 0x0b, 0x81, 0x66, 0xe0, 0x82, 0xa6,
        0x2d, 0x1b, 0xff, 0x6e, 0x91, 0x9d, 0x29, 0xad, 0x17, 0x18, 0x63, 0xc7, 0x8f, 0x0b, 0x97, 0xc8,
        0xe9, 0xae, 0x82, 0xae, 0x43, 0xd3,
        ]

    private let eviction2Headers: [Http2HeaderEntry] = [
        Http2HeaderEntry(field: ":status", value: "307"),
        Http2HeaderEntry(field: "cache-control", value: "private"),
        Http2HeaderEntry(field: "date", value: "Mon, 21 Oct 2013 20:13:21 GMT"),
        Http2HeaderEntry(field: "location", value: "https://www.example.com")
    ]

    private let eviction2Encoding: [UInt8] = [0x48, 0x83, 0x64, 0x0e, 0xff, 0xc1, 0xc0, 0xbf]

    private let eviction3Headers: [Http2HeaderEntry] = [
        Http2HeaderEntry(field: ":status", value: "200"),
        Http2HeaderEntry(field: "cache-control", value: "private"),
        Http2HeaderEntry(field: "date", value: "Mon, 21 Oct 2013 20:13:22 GMT"),
        Http2HeaderEntry(field: "location", value: "https://www.example.com"),
        Http2HeaderEntry(field: "content-encoding", value: "gzip"),
        Http2HeaderEntry(field: "set-cookie", value: "foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1")
    ]

    private let eviction3Encoding: [UInt8] = [
        0x88, 0xc1, 0x61, 0x96, 0xd0, 0x7a, 0xbe, 0x94, 0x10, 0x54, 0xd4, 0x44, 0xa8, 0x20, 0x05, 0x95,
        0x04, 0x0b, 0x81, 0x66, 0xe0, 0x84, 0xa6, 0x2d, 0x1b, 0xff, 0xc0, 0x5a, 0x83, 0x9b, 0xd9, 0xab,
        0x77, 0xad, 0x94, 0xe7, 0x82, 0x1d, 0xd7, 0xf2, 0xe6, 0xc7, 0xb3, 0x35, 0xdf, 0xdf, 0xcd, 0x5b,
        0x39, 0x60, 0xd5, 0xaf, 0x27, 0x08, 0x7f, 0x36, 0x72, 0xc1, 0xab, 0x27, 0x0f, 0xb5, 0x29, 0x1f,
        0x95, 0x87, 0x31, 0x60, 0x65, 0xc0, 0x03, 0xed, 0x4e, 0xe5, 0xb1, 0x06, 0x3d, 0x50, 0x07
    ]

    func testMultiEncodeWithEvictions() {
        let encoder = Http2HeaderEncoder(stringEncoding: .huffmanCode)
        encoder.headerTable.settingsHeaderTableSize = 256

        // http://tools.ietf.org/html/rfc7541#appendix-C.6.1
        var encoded = encoder.encode(headers: eviction1Headers, indexing: .literalHeaderIncremental)
        XCTAssertEqual(encoded, eviction1Encoding)
        XCTAssertEqual(encoder.headerTable.dynamicTable.count, 4)

        // https://tools.ietf.org/html/rfc7541#appendix-C.6.2
        encoded = encoder.encode(headers: eviction2Headers, indexing: .literalHeaderIncremental)
        XCTAssertEqual(encoded, eviction2Encoding)
        XCTAssertEqual(encoder.headerTable.dynamicTable.count, 4)

        // https://tools.ietf.org/html/rfc7541#appendix-C.6.3
        encoded = encoder.encode(headers: eviction3Headers, indexing: .literalHeaderIncremental)
        XCTAssertEqual(encoded, eviction3Encoding)
        XCTAssertEqual(encoder.headerTable.dynamicTable.count, 3)
    }

    func testMultiDecodeWithEvictions() {
        let decoder = Http2HeaderDecoder()
        decoder.headerTable.settingsHeaderTableSize = 256

        MyAssertNoThrow(try decoder.decode(encoded: eviction1Encoding)) {
            headersMatch(lhs: $0, rhs: eviction1Headers)
            XCTAssertEqual(decoder.headerTable.dynamicTable.count, 4)
        }

        MyAssertNoThrow(try decoder.decode(encoded: eviction2Encoding)) {
            headersMatch(lhs: $0, rhs: eviction2Headers)
            XCTAssertEqual(decoder.headerTable.dynamicTable.count, 4)
        }

        MyAssertNoThrow(try decoder.decode(encoded: eviction3Encoding)) {
            headersMatch(lhs: $0, rhs: eviction3Headers)
            XCTAssertEqual(decoder.headerTable.dynamicTable.count, 3)
        }
    }
}

