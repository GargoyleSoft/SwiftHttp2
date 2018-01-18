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

/// A CONTINUATION frame allows for more headers to be sent if the HEADERS packet is too small.
/// - See: https://tools.ietf.org/html/rfc7540#section-6.10
public final class ContinuationFrame: AbstractFrame, HasHeaders {
    /// The default type of indexing to use for the headers in this frame.  Defaults to `.none`
    public var headerFieldIndexType = Http2HeaderFieldIndexType.none

    /// The default type of encoding to use for this frame.  Defaults to `.huffmanCode`
    public var headerEncoding = Http2HeaderStringEncodingType.huffmanCode

    /// Whether or not the END_HEADERS flag is set.
    public var endHeaders = false

    /// The headers included in this frame.
    public var headers: [Http2HeaderTableEntry] = []

    /// The designated constructor.
    ///
    /// - Parameters:
    ///   - stream: The stream that this frame uses.
    ///   - endHeaders: Whether or not the END_HEADERS flag is set.
    ///   - headerFieldIndexType: The default type of indexing to use for the headers in this frame.  Defaults to `.none`
    ///   - headerEncoding: The default type of encoding to use for this frame.  Defaults to `.huffmanCode`
    /// - Throws: `FrameCodingError`
    public init(stream: Http2Stream, endHeaders: Bool = false, headerFieldIndexType: Http2HeaderFieldIndexType = .none, headerEncoding: Http2HeaderStringEncodingType = .huffmanCode) throws {
        self.endHeaders = endHeaders
        self.headerFieldIndexType = headerFieldIndexType
        self.headerEncoding = headerEncoding

        super.init(type: .continuation, stream: stream)

        headerEncoder.defaultStringEncoding = headerEncoding
    }

    override internal init(data: [UInt8]) throws {
        try super.init(data: data)

        try decodeHeaders(data: data, endIndex: data.endIndex)
    }

    /// Encodes the frame into a set of `UInt8` bytes.
    ///
    /// - Returns: The encoded frame data.
    /// - Throws: Various errors possible.
    override public func encode() throws -> [UInt8] {
        guard headers.isEmpty == false else {
            throw FrameCodingError.missingHeaders
        }

        var ret = try super.encode()

        ret += encodeHeaders()

        frameLength = ret.encodeFrameLength()

        return ret
    }
}

extension ContinuationFrame: HasFlags {
    internal func setFlags() throws {
        if endHeaders {
            flags = [.endHeaders]
        }
    }
}
