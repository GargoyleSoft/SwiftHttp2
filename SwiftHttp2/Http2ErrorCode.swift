// Copyright © 2018 Gargoyle Software, LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

public enum Http2Error : Error, CustomStringConvertible {
    case none
    case protocolError
    case internalError
    case flowControl
    case settingsTimeout
    case streamClosed
    case frameSize
    case refusedStream
    case cancel
    case compression
    case connect
    case enhanceYourCalm
    case inadequateSecurity
    case http11Required

    public var description: String {
        switch self {
        case .none: return "No Error"
        case .protocolError: return "Protocol Error"
        case .internalError: return "Internal Error"
        case .flowControl: return "Flow Control"
        case .settingsTimeout: return "Settings Timeout"
        case .streamClosed: return "Stream Closed"
        case .frameSize: return "Frame Size"
        case .refusedStream: return "Refused Stream"
        case .cancel: return "Cancel"
        case .compression: return "Compression"
        case .connect: return "Connect"
        case .enhanceYourCalm: return "Enhance Your Calm"
        case .inadequateSecurity: return "Inadequate Security"
        case .http11Required: return "HTTP 1/1 required"
        }
    }
}

public enum Http2ErrorCode: UInt32 {
    case none
    case protocolError
    case internalError
    case flowControl
    case settingsTimeout
    case streamClosed
    case frameSize
    case refusedStream
    case cancel
    case compression
    case connect
    case enhanceYourCalm
    case inadequateSecurity
    case http11Required
}

func +=(lhs: inout [UInt8], rhs: Http2ErrorCode) {
    lhs += rhs.rawValue.toByteArray()
}

