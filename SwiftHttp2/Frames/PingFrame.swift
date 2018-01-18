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

/// PING frames allow for measuring a minimal round-trip time from the sender, and are
/// also used to determine whether or not an idel connection is stil functional.
/// - See: https://tools.ietf.org/html/rfc7540#section-6.7
final public class PingFrame: AbstractFrame {
    /// Whether or not this is a PING response.
    private var ack: Bool = false

    /// Opaque data to include in the frame.
    public var data: UInt64 = 0

    /// Whether or not this is a PING response
    public var isAck: Bool {
        return ack
    }

    /// The designated initializer
    ///
    /// - Parameters:
    ///   - data: Opaque data to include in the frame.  Defaults to `0`
    ///   - ack: Whether or not this is a PING response.  Defaults to `false`
    /// - Throws: `FrameCodingError`
    public init(data: UInt64 = 0, ack: Bool = false) throws {
        self.ack = ack
        self.data = data

        super.init(type: .ping, stream: Http2Stream.connectionStream)
    }

    /// Convenience initializer allowing `String` data to be provided.
    ///
    /// - Parameters:
    ///   - data: Opaque data to include in the frame.  Defaults to `0`
    ///   - ack: Whether or not this is a PING response.  Defaults to `false`
    /// - Throws: `FrameCodingError`
    convenience init(data: String, ack: Bool = false) throws {
        let bytes = data.toUInt8Array()
        let opaque = try PingFrame.toUInt64(bytes: bytes)
        try self.init(data: opaque, ack: ack)
    }

    /// Convenience initializer allowing `Data` data to be provided.
    ///
    /// - Parameters:
    ///   - data: Opaque data to include in the frame.  Defaults to `0`
    ///   - ack: Whether or not this is a PING response.  Defaults to `false`
    /// - Throws: `FrameCodingError`
    convenience init(data: Data, ack: Bool = false) throws {
        let bytes = [UInt8](data)
        let opaque = try PingFrame.toUInt64(bytes: bytes)
        try self.init(data: opaque, ack: ack)
    }

    override internal init(data: [UInt8]) throws {
        try super.init(data: data)

        guard stream.identifier == Http2Stream.connectionStream.identifier else {
            throw Http2Error.protocolError
        }

        guard frameLength == 8 else {
            throw Http2Error.frameSize
        }

        self.data = UInt64(bytes: data, startIndex: decodeIndex)
    }

    private static func toUInt64(bytes: [UInt8]) throws -> UInt64 {
        guard bytes.count <= 64 else {
            throw FrameCodingError.dataTooLarge
        }

        return UInt64(bytes: bytes, startIndex: 0)
    }

    /// Encodes the frame into a set of `UInt8` bytes.
    ///
    /// - Returns: The encoded frame data.
    /// - Throws: Various errors possible.
    override public func encode() throws -> [UInt8] {
        var ret = try super.encode()
        ret += data

        frameLength = ret.encodeFrameLength()

        return ret
    }
}

extension PingFrame: HasFlags {
    internal func setFlags() throws {
        if ack {
            flags.formUnion(.ack)
        }
    }
}
