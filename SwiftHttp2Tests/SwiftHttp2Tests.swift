//
//  SwiftHttp2Tests.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/2/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2

// TODO: Complete all test cases at https://github.com/http2jp/http2-frame-test-case

class SwiftHttp2Tests: XCTestCase {
    static let nonConnectionStream = try! Http2StreamCache.shared.createStream(with: 1)

    func testConversion16() {
        let initial: UInt16 = 0b00100000_00000001

        let ary = initial.toByteArray()
        XCTAssertEqual(ary, [0b00100000, 0b00000001])

        let back = UInt16(bytes: ary, startIndex: 0)
        XCTAssertEqual(initial, back)
    }

    func testConversion32() {
        let initial: UInt32 = 0b10000000_00010000_00100000_00000001

        let ary = initial.toByteArray()
        XCTAssertEqual(ary, [0b10000000, 0b00010000, 0b00100000, 0b00000001])

        let back = UInt32(bytes: ary, startIndex: 0)
        XCTAssertEqual(initial, back)
    }

    func testConversion64() {
        let initial: UInt64 = 0b10000000_01000000_00100000_00010000_00001000_00000100_00000010_00000001
        let ary = initial.toByteArray()
        XCTAssertEqual(ary, [
            0b10000000, 0b01000000, 0b00100000, 0b00010000, 0b00001000, 0b00000100, 0b00000010, 0b00000001
            ])

        let back = UInt64(bytes: ary, startIndex: 0)
        XCTAssertEqual(initial, back)
    }
}
