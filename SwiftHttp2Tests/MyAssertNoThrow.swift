//
//  MyAssertNoThrow.swift
//  SwiftHttp2Tests
//
//  Created by Scott Grosch on 1/4/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import XCTest
@testable import SwiftHttp2

// https://medium.com/@hybridcattt/how-to-test-throwing-code-in-swift-c70a95535ee5
func MyAssertNoThrow<T>(_ expression: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line, also validateResult: (T) -> Void) {
    func executeAndAssignResult(_ expression: @autoclosure () throws -> T, to: inout T?) rethrows {
        to = try expression()
    }

    var result: T?
    XCTAssertNoThrow(try executeAndAssignResult(expression, to: &result), message, file: file, line: line)
    if let r = result {
        validateResult(r)
    }
}

func MyAssertThrowsError<T>(_ expression: @autoclosure () throws -> T, error e: Http2Error, file: StaticString = #file, line: UInt = #line) {
    do {
        _ = try expression()
    } catch let error as Http2Error where error == e {
        return
    } catch let error {
        XCTFail("Got an error but the wrong one: \(error.localizedDescription)", file: file, line: line)
    }

    XCTFail("Should have thrown an error", file: file, line: line)
}
