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

/// AN RST_STREAM frame immediately terminates a stream.
/// - See: https://tools.ietf.org/html/rfc7540#section-6.4
final public class RstStreamFrame: AbstractFrame {
    /// Why the stream is being terminated.
    public var errorCode: Http2ErrorCode = .none

    /// The designated initializer.
    ///
    /// - Parameters:
    ///   - stream: The stream which is being closed.
    ///   - errorCode: Why the stream is being terminated
    public init(stream: Http2Stream, errorCode: Http2ErrorCode = .none) {
        self.errorCode = errorCode

        super.init(type: .rstStream, stream: stream)
    }

    override internal init(data: [UInt8]) throws {
        try super.init(data: data)
        fatalError()
    }

    /// Encodes the frame into a set of `UInt8` bytes.
    ///
    /// - Returns: The encoded frame data.
    /// - Throws: Various errors possible.
    override public func encode() throws -> [UInt8] {
        var ret = try super.encode()
        ret += errorCode

        return ret
    }
}

