//
//  SwiftHttp2TestCase.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/6/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2

class SwiftHttp2TestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        Http2StreamCache.shared.initialize(as: .client)
    }

    func verifyEncoding<T : AbstractFrame>(for frame: T, using data: [UInt8], against dataCheck: (T, StaticString, UInt) -> Void, file: StaticString = #file, line: UInt = #line) {
        dataCheck(frame, file, line)

        MyAssertNoThrow(try frame.encode(), file: file, line: line) {
            XCTAssertEqual($0, data, file: file, line: line)
        }
    }

    func verifyFrameLengthSet<T : AbstractFrame>(_ expression: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        var f: T? = nil
        XCTAssertNoThrow(f = try expression(), file: file, line: line)
        guard let frame = f else { return }

        MyAssertNoThrow(try frame.encode(), file: file, line: line) {
            XCTAssertNotEqual($0[0...2], [0, 0, 0], file: file, line: line)
        }
    }

    func verifyPaddingDataOverridesPadLength<T : AbstractFrame & HasPadding>(frame: T, padding: String, file: StaticString = #file, line: UInt = #line) {
        let count = UInt8(truncatingIfNeeded: padding.count)
        XCTAssertEqual(frame.padLength, count, file: file, line: line)
    }

    func verifyNoPaddingWithLengthUsesLength<T : AbstractFrame & HasPadding>(_ expression: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        MyAssertNoThrow(try expression()) { frame in
            XCTAssertEqual(UInt8(frame.padding?.count ?? 0), frame.padLength)
        }
    }
}

