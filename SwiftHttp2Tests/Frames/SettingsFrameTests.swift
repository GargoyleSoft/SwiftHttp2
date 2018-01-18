//
//  SettingsFrameTests.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/4/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2

class SettingsFrameTests : SwiftHttp2TestCase {
    private let input1: [UInt8] = [
        0x00, 0x00, 0x0C, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x01, 0x00, 0x00, 0x20, 0x00,
        0x00, 0x03, 0x00, 0x00, 0x13, 0x88
    ]

    private func validate1(_ frame: SettingsFrame, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(frame.type, .settings, file: file, line: line)
        XCTAssertEqual(frame.flags, [], file: file, line: line)
        XCTAssertEqual(frame.stream.identifier, Http2Stream.connectionStream.identifier, file: file, line: line)
        XCTAssertEqual(frame.headerTableSize, 8192, file: file, line: line)
        XCTAssertEqual(frame.maxConcurrentStreams, 5000, file: file, line: line)
    }

    func testDecodesAsProperFrameType() {
        MyAssertNoThrow(try AbstractFrame.decode(data: Data(bytes: input1))) { (frame, idx) in
            XCTAssertTrue(frame is SettingsFrame)
        }
    }

    func testSettingsFrameEncode() {
        let frame = SettingsFrame(headerTableSize: 8192, maxConcurrentStreams: 5000)
        verifyEncoding(for: frame, using: input1, against: validate1)
    }

    func testDataFrameDecode() {
        MyAssertNoThrow(try SettingsFrame(data: input1)) {
            validate1($0)
        }
    }

    func testEnsureEmptySettingsFrameThrows() {
        XCTAssertThrowsError(try SettingsFrame().encode())
    }

    func testEnsureFrameLengthSet() {
        verifyFrameLengthSet(SettingsFrame(headerTableSize: 10))
    }

    func testUnknownSettingsIdentifierIgnored() {
        let input: [UInt8] = [0x00, 0x00, 0x06, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0, 0, 0, 0]
        XCTAssertNoThrow(try SettingsFrame(data:input))
    }
}
