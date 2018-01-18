//
//  GoAwayFrameTests.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/3/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2

class GoAwayFrameTests: SwiftHttp2TestCase {
    lazy var input1: [UInt8] = [
        0x00, 0x00, 0x17, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1E, 0x00, 0x00, 0x00, 0x09,
        0x68, 0x70, 0x61, 0x63, 0x6B, 0x20, 0x69, 0x73, 0x20, 0x62, 0x72, 0x6F, 0x6B, 0x65, 0x6E
    ]

    private func validate1(_ frame: GoAwayFrame, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(frame.type, .goAway, file: file, line: line)
        XCTAssertEqual(frame.flags, [], file: file, line: line)
        XCTAssertEqual(frame.stream.identifier, 0, file: file, line: line)
        XCTAssertEqual(frame.errorCode, .compression, file: file, line: line)
        XCTAssertNotNil(frame.debugData, file: file, line: line)
        XCTAssertEqual(frame.debugData!, "hpack is broken".toUInt8Array(), file: file, line: line)

        // This will always be false during a decode because we don't actually have a stream in our cache.
        if let lastStream = frame.lastStream {
            XCTAssertEqual(lastStream.identifier, 30, file: file, line: line)
        }
    }

    func testDecodesAsProperFrameType() {
        MyAssertNoThrow(try AbstractFrame.decode(data: Data(bytes: input1))) { (frame, idx) in
            XCTAssertTrue(frame is GoAwayFrame)
        }
    }

    func testEnsureFrameLengthSet() {
        verifyFrameLengthSet(GoAwayFrame(lastStream: Http2Stream.connectionStream))
    }

    func testEncode1() {
        MyAssertNoThrow(try Http2StreamCache.shared.createStream(with: 30)) {
            let frame = GoAwayFrame(lastStream: $0, errorCode: .compression, debugData: "hpack is broken")
            verifyEncoding(for: frame, using: input1, against: validate1)
        }
    }

    func testDecode1() {
        MyAssertNoThrow(try GoAwayFrame(data: input1)) {
            validate1($0)
        }
    }
}
