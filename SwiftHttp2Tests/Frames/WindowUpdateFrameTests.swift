//
//  WindowUpdateFrameTests.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/4/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2

 class WindowUpdateFrameTests: SwiftHttp2TestCase {

    override func setUp() {
        super.setUp()
        Http2StreamCache.shared.initialize(as: .client)
    }

    private let input1: [UInt8] = [0x00, 0x00, 0x04, 0x08, 0x00, 0x00, 0x00, 0x00, 0x32, 0x00, 0x00, 0x03, 0xE8]

    private func validate1(_ frame: WindowUpdateFrame, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(frame.type, .windowUpdate, file: file, line: line)
        XCTAssertEqual(frame.flags, [], file: file, line: line)
        XCTAssertEqual(frame.stream.identifier, 50, file: file, line: line)
        XCTAssertEqual(frame.sizeIncrement, 1000, file: file, line: line)
    }

    func testDecodesAsProperFrameType() {
        MyAssertNoThrow(try AbstractFrame.decode(data: Data(bytes: input1))) { (frame, idx) in
            XCTAssertTrue(frame is WindowUpdateFrame)
        }
    }

    func testSettingsFrameEncode() {
        MyAssertNoThrow(try Http2StreamCache.shared.createStream(with: 50)) {
            let frame = WindowUpdateFrame(stream: $0, sizeIncrement: 1000)
            verifyEncoding(for: frame, using: input1, against: validate1)
        }
    }

    func testDataFrameDecode() {
        MyAssertNoThrow(try WindowUpdateFrame(data: input1)) {
            validate1($0)
        }
    }

    func testEnsureFrameLengthSet() {
        verifyFrameLengthSet(WindowUpdateFrame(stream: Http2Stream.connectionStream, sizeIncrement: 1000))
    }
}
