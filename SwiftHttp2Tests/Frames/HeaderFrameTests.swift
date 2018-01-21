//
//  HeaderFrameTests.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/6/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2


class HeaderFrameTests: SwiftHttp2TestCase {
    private let octetEncoding: [UInt8] = [
        0x00, 0x00, 0x27, 0x01, 0x04, 0x00, 0x00, 0x00, 0x01, 0x83, 0x0F, 0x10, 0x10, 0x61, 0x70, 0x70,
        0x6C, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x2D, 0x6A, 0x73, 0x6F, 0x6E, 0x0F, 0x04, 0x10,
        0x61, 0x70, 0x70, 0x6C, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x2D, 0x6A, 0x73, 0x6F, 0x6E
    ]

    private let huffmanEncoding: [UInt8] = [
        0x00, 0x00, 0x1D, 0x01, 0x04, 0x00, 0x00, 0x00, 0x01, 0x83, 0x0F, 0x10, 0x8B, 0x1D, 0x75, 0xD0,
        0x62, 0x0D, 0x26, 0x3D, 0x4B, 0x74, 0x41, 0xEA, 0x0F, 0x04, 0x8B, 0x1D, 0x75, 0xD0, 0x62, 0x0D, 0x26, 0x3D, 0x4B, 0x74, 0x41, 0xEA
    ]

    private func validateOctetEncoding(_ frame: HeadersFrame, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(frame.type, .headers, file: file, line: line)
        XCTAssertEqual(frame.flags, [.endHeaders], file: file, line: line)
        XCTAssertEqual(frame.stream.identifier, 1, file: file, line: line)
        XCTAssertEqual(frame.headers.count, 3, file: file, line: line)
        XCTAssertEqual(frame.headerEncoding, .literalOctets, file: file, line: line)
    }

    private func validateHuffmanEncoding(_ frame: HeadersFrame, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(frame.type, .headers, file: file, line: line)
        XCTAssertEqual(frame.flags, [.endHeaders], file: file, line: line)
        XCTAssertEqual(frame.stream.identifier, 1, file: file, line: line)
        XCTAssertEqual(frame.headers.count, 3, file: file, line: line)
        XCTAssertEqual(frame.headerEncoding, .huffmanCode, file: file, line: line)
    }

    func testHeaderFrameOctetsEncode() {
        var s: Http2Stream? = nil
        XCTAssertNoThrow(s = try Http2StreamCache.shared.createStream(with: 1))
        guard let stream = s else { return }

        var f: HeadersFrame? = nil
        XCTAssertNoThrow(f = try HeadersFrame(stream: stream, endHeaders: true, headerEncoding: .literalOctets))
        guard let frame = f else { return }

        frame.add(headers: [
            Http2HeaderEntry(field: ":method", value: "POST"),
            Http2HeaderEntry(field: "Content-Type", value: "application-json"),
            Http2HeaderEntry(field: "Accept", value: "application-json")
            ])

        verifyEncoding(for: frame, using: octetEncoding, against: validateOctetEncoding)
        frame.headerEncoder.headerTable.dumpTableForUnitTests()
    }

    func testDataFromHuffmanEncode() {
        var s: Http2Stream? = nil
        XCTAssertNoThrow(s = try Http2StreamCache.shared.createStream(with: 1))
        guard let stream = s else { return }

        MyAssertNoThrow(try HeadersFrame(stream: stream, endHeaders: true, headerEncoding: .huffmanCode)) { frame in
            frame.add(headers: [
                Http2HeaderEntry(field: ":method", value: "POST"),
                Http2HeaderEntry(field: "Content-Type", value: "application-json"),
                Http2HeaderEntry(field: "Accept", value: "application-json")
                ])

            verifyEncoding(for: frame, using: huffmanEncoding, against: validateHuffmanEncoding)
        }
    }

    func testEnsureFrameLengthSet() {
        MyAssertNoThrow(try HeadersFrame(stream: Http2Stream.connectionStream, endHeaders: true)) { frame in
            frame.add(headers: [
                Http2HeaderEntry(field: ":method", value: "POST"),
                Http2HeaderEntry(field: "Content-Type", value: "application-json"),
                Http2HeaderEntry(field: "Accept", value: "application-json")
                ])
            verifyFrameLengthSet(frame)
        }
    }

    func testPaddingOverridesPadLength() {
        let padding = "qwer1234"
        let padLength = UInt8(padding.count * 10)

        MyAssertNoThrow(try HeadersFrame(stream: Http2Stream.connectionStream, padLength: padLength, padding: padding, endHeaders: true)) {
            verifyPaddingDataOverridesPadLength(frame: $0, padding: padding)
        }
    }

    func testNoPaddingWithLengthUsesLength() {
        verifyNoPaddingWithLengthUsesLength(try HeadersFrame(stream: Http2Stream.connectionStream, padLength: 10))
    }

    func testHeaderFrameMustHaveStream() {
        var f: HeadersFrame?
        XCTAssertNoThrow(f = try HeadersFrame(stream: Http2Stream.connectionStream))
        guard let frame = f else { return }

        frame.add(header: "foo", value: "bar")

        var e: [UInt8]?
        XCTAssertNoThrow(e = try frame.encode())
        guard let encoded = e else { return }

        MyAssertThrowsError(try HeadersFrame(data: encoded), error: .protocolError)
    }
}
