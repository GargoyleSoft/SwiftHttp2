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

/// Data frames send variable-length sequences of octets associated with a stream.
/// - See: https://tools.ietf.org/html/rfc7540#section-6.1
final public class DataFrame: AbstractFrame, HasPadding {
    /// The amount of padding to use on the frame.
    /// - Note: If `padding` is not `nil` this value is replaced with the `padding` length.
    public var padLength: UInt8 = 0

    /// The padding to use on the frame.
    /// - Note: If `nil`, and `padLength` is non-zero, then this will be filled with random values.
    public var padding: [UInt8]? = nil

    /// Whether or not the END_STREAM flag is present in the frame.
    public var endStream: Bool = false

    /// The bytes of data to send with the frame.
    public var data: [UInt8]? = nil

    /// The designated initializer.
    ///
    /// - Parameters:
    ///   - stream: The stream that this frame uses.
    ///   - padLength: The amount of padding to use on the frame.
    ///   - padding: The padding to use on the frame.
    ///   - endStream: Whether or not the END_STREAM flag is set.
    ///   - data: The bytes of data to send with the frame.
    /// - Throws: `Http2Error` or `FrameCodingError`
    /// - Note: If `padding` is not `nil` the `padLength` value is ignored.  If `padding` is `nil` and `padLength`
    ///         is not `nil`, then `padding` will be filled with that many random bytes.
    public init(stream: Http2Stream, padLength: UInt8 = 0, padding: [UInt8]? = nil, endStream: Bool = false, data: [UInt8]? = nil) throws {
        self.endStream = endStream
        self.data = data

        super.init(type: .data, stream: stream)

        guard !stream.isConnectionStream else {
            throw Http2Error.protocolError
        }

        try initialize(padding: padding, length: padLength)
    }

    /// Convenience initializer allowing `String` `data` to be provided.
    ///
    /// - Parameters:
    ///   - stream: The stream that this frame uses.
    ///   - padLength: The amount of padding to use on the frame.
    ///   - padding: The padding to use on the frame.
    ///   - endStream: Whether or not the END_STREAM flag is set.
    ///   - data: The bytes of data to send with the frame.
    /// - Throws: `Http2Error` or `FrameCodingError`
    /// - Note: If `padding` is not `nil` the `padLength` value is ignored.  If `padding` is `nil` and `padLength`
    ///         is not `nil`, then `padding` will be filled with that many random bytes.
    convenience public init(stream: Http2Stream, padLength: UInt8 = 0, padding: [UInt8]? = nil, endStream: Bool = false, data: String) throws {
        let encodedData = data.toUInt8Array()
        try self.init(stream: stream, padLength: padLength, padding: padding, endStream: endStream, data: encodedData)
    }

    /// Convenience initializer allowing `String` `padding` and `data` to be specified
    ///
    /// - Parameters:
    ///   - stream: The stream that this frame uses.
    ///   - padLength: The amount of padding to use on the frame.
    ///   - padding: The padding to use on the frame.
    ///   - endStream: Whether or not the END_STREAM flag is set.
    ///   - data: The data to send with the frame.
    /// - Throws: `Http2Error` or `FrameCodingError`
    /// - Note: If `padding` is not `nil` the `padLength` value is ignored.  If `padding` is `nil` and `padLength`
    ///         is not `nil`, then `padding` will be filled with that many random bytes.
    convenience public init(stream: Http2Stream, padLength: UInt8 = 0, padding: String, endStream: Bool = false, data: String) throws {
        let encodedPadding = padding.toUInt8Array()
        let encodedData = data.toUInt8Array()

        try self.init(stream: stream, padLength: padLength, padding: encodedPadding, endStream: endStream, data: encodedData)
    }

    /// Convenience initializer allowing `String` `padding` to be specified
    ///
    /// - Parameters:
    ///   - stream: The stream that this frame uses.
    ///   - padLength: The amount of padding to use on the frame.
    ///   - padding: The padding to use on the frame.
    ///   - endStream: Whether or not the END_STREAM flag is set.
    ///   - data: The bytes of data to send with the frame.
    /// - Throws: `Http2Error` or `FrameCodingError`
    /// - Note: If `padding` is not `nil` the `padLength` value is ignored.  If `padding` is `nil` and `padLength`
    ///         is not `nil`, then `padding` will be filled with that many random bytes.
    convenience public init(stream: Http2Stream, padLength: UInt8 = 0, padding: String, endStream: Bool = false, data: [UInt8]) throws {
        let encodedPadding = padding.toUInt8Array()
        try self.init(stream: stream, padLength: padLength, padding: encodedPadding, endStream: endStream, data: data)
    }

    override internal init(data: [UInt8]) throws {
        try super.init(data: data)

        guard !stream.isConnectionStream else {
            throw Http2Error.protocolError
        }
        
        decodePadLengthIfNecessary(data: data[decodeIndex])

        let lastDataIndex = data.endIndex - Int(padLength)

        if decodeIndex >= lastDataIndex {
            throw Http2Error.protocolError
        }

        self.data = [UInt8](data[decodeIndex ..< lastDataIndex])
        padding = decodePaddingIfNecessary(data: data, from: lastDataIndex)

    }

    /// Encodes the frame into a set of `UInt8` bytes.
    ///
    /// - Returns: The encoded frame data.
    /// - Throws: Various errors possible.
    override public func encode() throws -> [UInt8] {
        var ret = try super.encode()

        ret += encodePadLengthIfNecessary()

        if let data = data {
            ret += data
        }

        ret += try encodePaddingIfNecessary()

        frameLength = ret.encodeFrameLength()

        if ret.count - AbstractFrame.frameHeaderLength == padLength {
            throw Http2Error.protocolError
        }

        return ret
    }
}

extension DataFrame : HasFlags {
    internal func setFlags() throws {
        if padLength > 0 {
            flags.formUnion(.padded)
        }

        if endStream {
            flags.formUnion(.endStream)
        }
    }
}
