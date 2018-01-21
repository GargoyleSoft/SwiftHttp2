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

/// PUSH_PROMISE frames notify peers in advance of streams the sender intends to initiate.
/// - See: https://tools.ietf.org/html/rfc7540#section-6.6
final public class PushPromiseFrame: AbstractFrame, HasPadding, HasHeaders {
    /// The amount of padding to use on the frame.
    /// - Note: If `padding` is not `nil` this value is replaced with the `padding` length.
    public var padLength: UInt8 = 0

    /// The padding to use on the frame.
    /// - Note: If `nil`, and `padLength` is non-zero, then this will be filled with random values.
    public var padding: [UInt8]? = nil

    /// The stream that is reserved by the PUSH_PROMISE frame
    public var promisedStream: Http2Stream! = nil

    /// The default type of indexing to use for the headers in this frame.  Defaults to `.none`
    public var headerFieldIndexType = Http2HeaderFieldIndexType.literalHeaderNone

    /// The default type of encoding to use for this frame.  Defaults to `.huffmanCode`
    public var headerEncoding = Http2HeaderStringEncodingType.huffmanCode

    /// The headers included in this frame.
    public var headers: [Http2HeaderEntry] = []

    /// Whether or not the END_HEADERS flag is present in the frame.
    public var endHeaders = false

    /// The designated initializer.
    ///
    /// - Parameters:
    ///   - stream: The stream associated with this frame.
    ///   - promisedStream: The stream that is reserved by the PUSH_PROMISE frame.
    ///   - padLength: The amount of padding to use on the frame.
    ///   - padding: The padding to use on the frame.
    ///   - endHeaders: Whether or not the END_HEADERS flag is present in the frame.
    /// - Throws: `FrameCodingError`
    public init(stream: Http2Stream, promisedStream: Http2Stream, padLength: UInt8 = 0, padding: [UInt8]? = nil, endHeaders: Bool = false) throws {
        self.promisedStream = promisedStream
        self.endHeaders = endHeaders

        super.init(type: .pushPromise, stream: stream)
        try initialize(padding: padding, length: padLength)
    }

    /// Convenience initializer allowing the `padding` to be specified as a `String`
    ///
    /// - Parameters:
    ///   - stream: The stream associated with this frame.
    ///   - promisedStream: The stream that is reserved by the PUSH_PROMISE frame.
    ///   - padLength: The amount of padding to use on the frame.
    ///   - padding: The padding to use on the frame.
    ///   - endHeaders: Whether or not the END_HEADERS flag is present in the frame.
    /// - Throws: `FrameCodingError`
    convenience public init(stream: Http2Stream, promisedStream: Http2Stream, padLength: UInt8 = 0, padding: String, endHeaders: Bool = false) throws {
        let encodedPadding = [UInt8](padding.utf8)
        try self.init(stream: stream, promisedStream: promisedStream, padLength: padLength, padding: encodedPadding, endHeaders: endHeaders)
    }

    override internal init(data: [UInt8]) throws {
        try super.init(data: data)

        decodePadLengthIfNecessary(data: data[decodeIndex])

        let lastDataIndex = data.endIndex - Int(padLength)
        try decodeHeaders(data: data, endIndex: lastDataIndex)

        padding = decodePaddingIfNecessary(data: data, from: lastDataIndex)
    }

    /// Encodes the frame into a set of `UInt8` bytes.
    ///
    /// - Returns: The encoded frame data.
    /// - Throws: Various errors possible.
    override public func encode() throws -> [UInt8] {
        var ret = try super.encode()

        ret += encodePadLengthIfNecessary()
        ret += promisedStream.identifier
        ret += encodeHeaders()
        ret += try encodePaddingIfNecessary()

        return ret
    }
}

extension PushPromiseFrame: HasFlags {
    internal func setFlags() throws {
        if padLength > 0 {
            flags.formUnion(.padded)
        }

        if endHeaders {
            flags.formUnion(.endHeaders)
        }
    }
}
