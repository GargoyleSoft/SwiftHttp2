//
//  PriorityFrameTests.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/6/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2

class PriorityFrameTests: SwiftHttp2TestCase {
    private let input1: [UInt8] = [
        0x00, 0x00, 0x05, 0x02, 0x00, 0x00, 0x00, 0x00, 0x09, 0x00, 0x00, 0x00, 0x0B, 0x07
    ]

    private func validate1(_ frame: PriorityFrame, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(frame.type, .priority, file: file, line: line)
        XCTAssertEqual(frame.stream.identifier, 9, file: file, line: line)
        XCTAssertEqual(frame.priorityWeight, 8, file: file, line: line)
        XCTAssertEqual(frame.dependsOnStreamExclusively, false, file: file, line: line)
        XCTAssertEqual(frame.flags, [], file: file, line: line)
    }

    func testDecodesAsProperFrameType() {
        MyAssertNoThrow(try AbstractFrame.decode(data: Data(bytes: input1))) { (frame, idx) in
            XCTAssertTrue(frame is PriorityFrame)
        }
    }

    func testPriorityFrameEncode() {
        var s: Http2Stream? = nil
        XCTAssertNoThrow(s = try Http2StreamCache.shared.createStream(with: 11))
        guard let dependsOn = s else { return }

        MyAssertNoThrow(try Http2StreamCache.shared.createStream(with: 9)) {
            let frame = PriorityFrame(stream: $0, dependsOn: dependsOn, priorityWeight: 8)
            verifyEncoding(for: frame, using: input1, against: validate1)
        }
    }

    func testPriorityFrameDecode() {
        // When we decode it wants to find stream 9, so make sure one exists.
        var s: Http2Stream? = nil
        XCTAssertNoThrow(s = try Http2StreamCache.shared.createStream(with: 9))
        guard let _ = s else { return }

        MyAssertNoThrow(try PriorityFrame(data: input1)) {
            validate1($0)
        }
    }

    func testPriorityFrameMustHaveStream() {
        let frame = PriorityFrame(stream: Http2Stream.connectionStream, dependsOn: Http2Stream.connectionStream)

        var e: [UInt8]?
        XCTAssertNoThrow(e = try frame.encode())
        guard let encoded = e else { return }

        MyAssertThrowsError(try PriorityFrame(data: encoded), error: .protocolError)
    }

    func testPriorityFrameMustBeLength5() {
        // This is a really stupid test.  How should this be written?
        MyAssertThrowsError(try PriorityFrame(data: [0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0]), error: .protocolError)
    }
}
