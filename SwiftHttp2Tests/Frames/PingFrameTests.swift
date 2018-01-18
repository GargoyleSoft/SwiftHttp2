//
//  PingFrameTests.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/4/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2

class PingFrameTests: SwiftHttp2TestCase {
    private let input1: [UInt8] = [
        0x00, 0x00, 0x08, 0x06, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x64, 0x65, 0x61, 0x64, 0x62, 0x65, 0x65, 0x66
    ]

    private func validate1(_ frame: PingFrame, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(frame.type, .ping, file: file, line: line)
        XCTAssertEqual(frame.flags, [], file: file, line: line)
        XCTAssertEqual(frame.stream.identifier, Http2Stream.connectionStream.identifier, file: file, line: line)
    }

    func testDecodesAsProperFrameType() {
        MyAssertNoThrow(try AbstractFrame.decode(data: Data(bytes: input1))) { (frame, idx) in
            XCTAssertTrue(frame is PingFrame)
        }
    }

    func testSettingsFrameEncode() {
        MyAssertNoThrow(try PingFrame(data: "deadbeef")) {
            verifyEncoding(for: $0, using: input1, against: validate1)
        }
    }

    func testDataFrameDecode() {
        MyAssertNoThrow(try PingFrame(data: input1)) {
            validate1($0)
        }
    }

    func testEnsureFrameLengthSet() {
        verifyFrameLengthSet(try PingFrame(data: input1))
    }

    func testPingStreamMustBeNonZero() {
        MyAssertThrowsError(try PingFrame(data: [0, 0, 8, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]), error: .protocolError)
    }
}
