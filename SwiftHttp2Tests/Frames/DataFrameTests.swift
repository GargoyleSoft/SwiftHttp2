//
//  FrameTests.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/2/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2

class DataFrameTests: SwiftHttp2TestCase {
    private let input1: [UInt8] = [
        0x00, 0x00, 0x14, 0x00, 0x08, 0x00, 0x00, 0x00, 0x02, 0x06, 0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x2C,
        0x20, 0x77, 0x6F, 0x72, 0x6C, 0x64, 0x21, 0x48, 0x6F, 0x77, 0x64, 0x79, 0x21
    ]

    private func validate1(_ frame: DataFrame, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(frame.type, .data, file: file, line: line)
        XCTAssertEqual(frame.flags, .padded, file: file, line: line)
        XCTAssertEqual(frame.stream.identifier, 2, file: file, line: line)
        XCTAssertEqual(frame.data!.toString(), "Hello, world!", file: file, line: line)
        XCTAssertEqual(frame.padLength, 6, file: file, line: line)
        XCTAssertEqual(frame.padding!.toString(), "Howdy!", file: file, line: line)
    }

    func testDecodesAsProperFrameType() {
        MyAssertNoThrow(try AbstractFrame.decode(data: Data(bytes: input1))) { (frame, idx) in
            XCTAssertTrue(frame is DataFrame)
        }
    }

    func testDataFrameEncode() {
        var s: Http2Stream? = nil
        XCTAssertNoThrow(s = try Http2StreamCache.shared.createStream(with: 2))
        guard let stream = s else { return }

        MyAssertNoThrow(try DataFrame(stream: stream, padLength: 6, padding: "Howdy!", data: "Hello, world!")) {
            verifyEncoding(for: $0, using: input1, against: validate1)
        }
    }

    func testDataFrameDecode() {
        MyAssertNoThrow(try DataFrame(data: input1)) {
            validate1($0)
        }
    }

    func testEnsureFrameLengthSet() {
        verifyFrameLengthSet(try DataFrame(stream: SwiftHttp2Tests.nonConnectionStream, data: "Hi"))
    }

    func testPaddingOverridesPadLength() {
        let padding = "qwer1234"
        let padLength = UInt8(padding.count * 10)

        MyAssertNoThrow(try DataFrame(stream: SwiftHttp2Tests.nonConnectionStream, padLength: padLength, padding: padding, data: "q")) {
            verifyPaddingDataOverridesPadLength(frame: $0, padding: padding)
        }
    }

    func testNoPaddingWithLengthUsesLength() {
        verifyNoPaddingWithLengthUsesLength(try DataFrame(stream: SwiftHttp2Tests.nonConnectionStream, padLength: 10))
    }

    func testEncodedDataFrameMustHaveStream() {
        MyAssertThrowsError(try DataFrame(stream: Http2Stream.connectionStream), error: .protocolError)
    }

    func testDecodedDataFrameMustHaveStream() {
        MyAssertThrowsError(try DataFrame(data: [0, 0, 1, 0, 0, 0, 0, 0, 0, 1]), error: .protocolError)
    }
}
