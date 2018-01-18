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

/// The window frame is used to implement flow control:
/// - See: https://tools.ietf.org/html/rfc7540#section-6.9
public final class WindowUpdateFrame: AbstractFrame {
    /// The number of octets that the sender can transmit in addition to the existing flow-control window.
    public var sizeIncrement: UInt32 = 0

    /// The designated initializer.
    ///
    /// - Parameters:
    ///   - stream: The stream that this frame applies to.
    ///   - sizeIncrement: The number of octets that the sender can transmit in addition to the
    ///                    existing flow-control window.
    public init(stream: Http2Stream, sizeIncrement: UInt32) {
        self.sizeIncrement = sizeIncrement & ~(1 << 31)

        super.init(type: .windowUpdate, stream: stream)
    }

    override internal init(data: [UInt8]) throws {
        try super.init(data: data)

        guard frameLength == 4 else {
            throw Http2Error.frameSize
        }

        self.sizeIncrement = UInt32(bytes: data, startIndex: decodeIndex)
        if (self.sizeIncrement & 0b01111111_11111111_11111111_11111111) == 0 {
            throw Http2Error.flowControl
        }
    }

    /// Encodes the frame into a set of `UInt8` bytes.
    ///
    /// - Returns: The encoded frame data.
    /// - Throws: Various errors possible.
    override public func encode() throws -> [UInt8] {
        var ret = try super.encode()
        ret += sizeIncrement

        frameLength = ret.encodeFrameLength()

        return ret
    }
}
