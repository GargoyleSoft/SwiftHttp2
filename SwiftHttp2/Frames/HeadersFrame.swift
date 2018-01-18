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

/// HEADERS frames open a stream and additionally carry a header block fragment.
/// - See: https://tools.ietf.org/html/rfc7540#section-6.2
final public class HeadersFrame: AbstractFrame, HasFramePriority, HasPadding, HasHeaders {
    /// The amount of padding to use on the frame.
    /// - Note: If `padding` is not `nil` this value is replaced with the `padding` length.
    public var padLength: UInt8 = 0

    /// The padding to use on the frame.
    /// - Note: If `nil`, and `padLength` is non-zero, then this will be filled with random values.
    public var padding: [UInt8]? = nil
    
    /// Whether or not the END_STREAM flag is present in the frame.
    public var endStream = false

    /// Whether or not the END_HEADERS flag is present in the frame.
    public var endHeaders = false

    /// The default type of indexing to use for the headers in this frame.  Defaults to `.none`
    public var headerFieldIndexType = Http2HeaderFieldIndexType.none

    /// The default type of encoding to use for this frame.  Defaults to `.huffmanCode`
    public var headerEncoding = Http2HeaderStringEncodingType.huffmanCode

    /// The headers included in this frame.
    public var headers: [Http2HeaderTableEntry] = []
    
    /// The stream that this frame is dependent upon.
    public var dependsOn: Http2Stream? = nil

    /// Whether or not the stream dependency is exclusive.
    public var dependsOnStreamExclusively = false

    /// The priority weight for the stream, between 0 and 255.
    public var priorityWeight: UInt8 = 0

    /// The designated initializer.
    ///
    /// - Parameters:
    ///   - stream: The stream associated with this frame.
    ///   - padLength: The amount of padding to use on the frame.
    ///   - padding: The padding to use on the frame.
    ///   - endStream: Whether or not the END_STREAM flag is present in the frame.
    ///   - endHeaders: Whether or not the END_HEADERS flag is present in the frame.
    ///   - headerFieldIndexType: The default type of indexing to use for the headers in this frame.  Defaults to `.none`
    ///   - headerEncoding: The default type of encoding to use for this frame.  Defaults to `.huffmanCode`
    ///   - dependsOn: The stream that this frame is dependent upon.
    ///   - dependsOnStreamExclusively: Whether or not the stream dependency is exclusive.
    ///   - priorityWeight: The priority weight for the stream, between 0 and 255.
    /// - Throws: `FrameCodingError`
    public init(stream: Http2Stream, padLength: UInt8 = 0, padding: [UInt8]? = nil, endStream: Bool = false, endHeaders: Bool = false, headerFieldIndexType: Http2HeaderFieldIndexType = .none, headerEncoding: Http2HeaderStringEncodingType = .huffmanCode, dependsOn: Http2Stream? = nil, dependsOnStreamExclusively: Bool = false, priorityWeight: UInt8 = 0) throws {
        self.endStream = endStream
        self.endHeaders = endHeaders
        self.headerFieldIndexType = headerFieldIndexType
        self.headerEncoding = headerEncoding
        self.dependsOn = dependsOn
        self.dependsOnStreamExclusively = dependsOnStreamExclusively
        self.priorityWeight = priorityWeight

        super.init(type: .headers, stream: stream)
        try initialize(padding: padding, length: padLength)
        headerEncoder.defaultStringEncoding = headerEncoding
    }

    /// Convenience initializer allowing `String` padding to be provided.
    ///
    /// - Parameters:
    ///   - stream: The stream associated with this frame.
    ///   - padLength: The amount of padding to use on the frame.
    ///   - padding: The padding to use on the frame.
    ///   - endStream: Whether or not the END_STREAM flag is present in the frame.
    ///   - endHeaders: Whether or not the END_HEADERS flag is present in the frame.
    ///   - headerFieldIndexType: The default type of indexing to use for the headers in this frame.  Defaults to `.none`
    ///   - headerEncoding: The default type of encoding to use for this frame.  Defaults to `.huffmanCode`
    ///   - dependsOn: The stream that this frame is dependent upon.
    ///   - dependsOnStreamExclusively: Whether or not the stream dependency is exclusive.
    ///   - priorityWeight: The priority weight for the stream, between 0 and 255.
    /// - Throws: `FrameCodingError`
    convenience init(stream: Http2Stream, padLength: UInt8 = 0, padding: String, endStream: Bool = false, endHeaders: Bool = false, headerFieldIndexType: Http2HeaderFieldIndexType = .none, headerEncoding: Http2HeaderStringEncodingType = .huffmanCode, dependsOn: Http2Stream? = nil, dependsOnStreamExclusively: Bool = false, priorityWeight: UInt8 = 0) throws {
        try self.init(stream: stream, padLength: padLength, padding: [UInt8](padding.utf8), endStream: endStream, endHeaders: endHeaders, headerFieldIndexType: headerFieldIndexType, headerEncoding: headerEncoding, dependsOn: dependsOn, dependsOnStreamExclusively: dependsOnStreamExclusively, priorityWeight: priorityWeight)
    }

    override internal init(data: [UInt8]) throws {
        try super.init(data: data)

        guard stream != Http2Stream.connectionStream else {
            throw Http2Error.protocolError
        }

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
        ret += try encodePriority()
        ret += encodeHeaders()
        ret += try encodePaddingIfNecessary()

        frameLength = ret.encodeFrameLength()
        
        return ret 
    }
}

extension HeadersFrame: HasFlags {
    internal func setFlags() throws {
        if (priorityWeight > 0 || dependsOnStreamExclusively) && dependsOn == nil {
            throw FrameCodingError.missingDependsOnStream
        }

        if dependsOn != nil {
            flags.formUnion(.priority)
        }

        if padLength > 0 {
            flags.formUnion(.padded)
        }

        if endStream {
            flags.formUnion(.endStream)
        }

        if endHeaders {
            flags.formUnion(.endHeaders)
        }
    }
}
