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

/// The error type thrown when padding is too large
///
/// - paddingTooLarge: If the specified padding is bigger than allowed.
public enum PaddingError: Error {
    case paddingTooLarge
}

/// The error type thrown when a frame can't be properly encoded or decoded.
///
/// - packetTooShort: The packet is shorter than necessary to fully decode the frame.
/// - invalidFrameType: An unknown frame type was specified.
/// - invalidFrameFlags: An unknown frame flag was specified.
/// - invalidErrorCode: An invalid error code was specified.
/// - dataTooLarge: If the size of the data packet is too large.
/// - missingDependsOnStream: The frame is missing the "Depends On" stream identifier.
/// - missingHeaders: The frame is missing required headers
public enum FrameCodingError: Error {
    case packetTooShort
    case invalidFrameType
    case invalidFrameFlags
    case invalidErrorCode
    case dataTooLarge
    case missingDependsOnStream
    case missingHeaders
}

/// The base class that all frames derive from.
public class AbstractFrame {
    internal static let frameHeaderLength = 9

    internal let type: FrameType
    internal var flags: FrameFlags = []
    internal var decodeIndex = AbstractFrame.frameHeaderLength
    internal var stream: Http2Stream
    internal var frameLength: UInt32 = 0

    internal lazy var headerEncoder: Http2HeaderEncoder = {
        return Http2HeaderEncoder()
    }()

    internal lazy var headerDecoder: Http2HeaderDecoder = {
        return Http2HeaderDecoder()
    }()

    internal init(type: FrameType, stream: Http2Stream) {
        self.type = type
        self.stream = stream
    }

    internal init(data: [UInt8]) throws {
        guard data.count > AbstractFrame.frameHeaderLength else {
            throw FrameCodingError.packetTooShort
        }

        frameLength = (UInt32(data[0]) << 16) | (UInt32(data[1]) << 8) | UInt32(data[2])
        guard data.count == frameLength + UInt32(AbstractFrame.frameHeaderLength) else {
            throw FrameCodingError.packetTooShort
        }

        guard let type = FrameType(rawValue: data[3]) else {
            throw FrameCodingError.invalidFrameType
        }

        self.type = type

        flags = FrameFlags(rawValue: data[4])

        let identifier = UInt32(bytes: data, startIndex: 5)
        if let stream = Http2StreamCache.shared.stream(with: identifier) {
            self.stream = stream
        } else {
            self.stream = try Http2StreamCache.shared.createStream(with: identifier)
        }

        if let me = self as? HasFlags {
            try me.setFlags()
        }
    }

    internal func encode() throws -> [UInt8] {
        if let me = self as? HasFlags {
            flags = []
            try me.setFlags()
        }

        var ret: [UInt8] = [
            0, 0, 0,
            type.rawValue,
            flags.rawValue
        ]

        ret += stream.identifier

        return ret
    }

    /// Decodes a set of bytes into an HTTP/2 frame.  This is the main entry point for any application
    /// that wants to decode an HTTP/2 stream.
    ///
    /// - Parameter data: The input bytes.
    /// - Returns: A decoded HTTP/2 frame and the index of the next byte to start decoding
    /// - Throws: A `FrameDecodingError` or `Http2Error` on failure.
    public class func decode<Bytes : Collection>(data: Bytes) throws -> (AbstractFrame, Bytes.Index?) where Bytes.Element == UInt8, Bytes.IndexDistance == Int {
        guard data.count > AbstractFrame.frameHeaderLength else {
            throw FrameCodingError.packetTooShort
        }

        let endIndex = data.index(data.startIndex, offsetBy: 3)
        let encodedLength = [UInt8](data[data.startIndex ..< endIndex])

        let length = Int(UInt32(encodedLength[0] << 16) | UInt32(encodedLength[1] << 8) | UInt32(encodedLength[2])) + AbstractFrame.frameHeaderLength

        guard data.count >= length else {
            throw FrameCodingError.packetTooShort
        }

        guard let type = FrameType(rawValue: data[data.index(data.startIndex, offsetBy: 3)]) else {
            throw FrameCodingError.invalidFrameType
        }

        let frameData: [UInt8]
        let nextFrameStartIndex = data.index(data.startIndex, offsetBy: length, limitedBy: data.endIndex)
        if let nextFrameStartIndex = nextFrameStartIndex{
            frameData = [UInt8](data[data.startIndex ..< nextFrameStartIndex])
        } else {
            frameData = [UInt8](data)
        }

        let constructor: ((_ data: [UInt8]) throws -> AbstractFrame)

        switch type {
        case .continuation:
            constructor = ContinuationFrame.init
        case .data:
            constructor = DataFrame.init
        case .goAway:
            constructor = GoAwayFrame.init
        case .headers:
            constructor = HeadersFrame.init
        case .ping:
            constructor = PingFrame.init
        case .priority:
            constructor = PriorityFrame.init
        case .pushPromise:
            constructor = PushPromiseFrame.init
        case .rstStream:
            constructor = RstStreamFrame.init
        case .settings:
            constructor = SettingsFrame.init
        case .windowUpdate:
            constructor = WindowUpdateFrame.init
        }

        return (try constructor(frameData), nextFrameStartIndex)
    }
}
