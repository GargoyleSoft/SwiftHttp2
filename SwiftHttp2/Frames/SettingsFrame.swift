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

private enum SettingsIdentifier: UInt16 {
    case headerTableSize = 0x1
    case enablePush
    case maxConcurrentStreams
    case initialWindowSize
    case maxFrameSize
    case maxHeaderListSize
}

private func +=(lhs: inout [UInt8], rhs: SettingsIdentifier) {
    lhs += rhs.rawValue.toByteArray()
}

/// SETTINGS frames convey configuration parameters.
/// - See: https://tools.ietf.org/html/rfc7540#section-6.5
final public class SettingsFrame : AbstractFrame {
    /// Whether or not this is a SETTINGS acknowledgement response.
    private var ack: Bool = false

    /// Maximum size of the header compression table used to decode header blocks.
    public var headerTableSize: UInt32? = nil

    /// Whether or not server push is enabled.
    public var enablePush: Bool = false

    /// Maximum number of concurrent straems that the sender will allow.
    public var maxConcurrentStreams: UInt32? = nil

    /// Sender's initial window size, in octets for stream-level flow control
    public var initialWindowSize: UInt32? = nil

    /// The size of the largest frame payload that the sender is willing to receive, in octets.
    public var maxFrameSize: UInt32? = nil

    /// Advisory settings informing a peer of the maximum size of the header list, in octets, that we will accept.
    public var maxHeaderListSize: UInt32? = nil

    /// The designated initializer.
    ///
    /// - Parameters:
    ///   - ack: Whether or not this is a SETTINGS acknowledgement response.
    ///   - headerTableSize: Maximum size of the header compression table used to decode header blocks.
    ///   - enablePush: Whether or not server push is enabled.
    ///   - maxConcurrentStreams: Maximum number of concurrent straems that the sender will allow.
    ///   - initialWindowSize: Sender's initial window size, in octets for stream-level flow control
    ///   - maxFrameSize: The size of the largest frame payload that the sender is willing to receive, in octets.
    ///   - maxHeaderListSize: Advisory settings informing a peer of the maximum size of the header list, in octets, that we will accept.
    public init(ack: Bool = false, headerTableSize: UInt32? = nil, enablePush: Bool = false, maxConcurrentStreams: UInt32? = nil, initialWindowSize: UInt32? = nil, maxFrameSize: UInt32? = nil, maxHeaderListSize: UInt32? = nil) {
        self.ack = ack
        self.headerTableSize = headerTableSize
        self.enablePush = enablePush
        self.maxConcurrentStreams = maxConcurrentStreams
        self.initialWindowSize = initialWindowSize
        self.maxFrameSize = maxFrameSize
        self.maxHeaderListSize = maxHeaderListSize

        super.init(type: .settings, stream: Http2Stream.connectionStream)
    }

    override internal init(data: [UInt8]) throws {
        try super.init(data: data)

        if stream.identifier != Http2Stream.connectionStream.identifier {
            throw Http2Error.protocolError
        }

        // Settings frames must have a length which is a multiple of 6 octets
        if frameLength % 6 != 0 || frameLength == 0 {
            throw Http2Error.frameSize
        }

        if flags.contains(.ack) {
            ack = true
            guard data.count == 0 else {
                throw Http2Error.frameSize
            }

            return
        }

        while decodeIndex < data.endIndex {
            defer { decodeIndex += 6 }

            let ident = UInt16(bytes: data, startIndex: decodeIndex)
            guard let settingsIdentifier = SettingsIdentifier(rawValue: ident) else {
                continue
            }

            let value = UInt32(bytes: data, startIndex: decodeIndex + 2)

            switch settingsIdentifier {
            case .enablePush:
                switch value {
                case 0: enablePush = false
                case 1: enablePush = true
                default: throw Http2Error.protocolError
                }

            case .headerTableSize:
                headerTableSize = value

            case .initialWindowSize:
                initialWindowSize = value

            case .maxConcurrentStreams:
                maxConcurrentStreams = value

            case .maxFrameSize:
                maxFrameSize = value

            case .maxHeaderListSize:
                maxHeaderListSize = value
            }
        }
    }

    /// Whether or not this is a SETTINGS acknowledgement response.
    public var isAck: Bool {
        return ack
    }

    /// Encodes the frame into a set of `UInt8` bytes.
    ///
    /// - Returns: The encoded frame data.
    /// - Throws: Various errors possible.
    override public func encode() throws -> [UInt8] {
        var ret = try super.encode()

        if flags.contains(.ack) {
            return ret
        }

        if let headerTableSize = headerTableSize {
            ret += SettingsIdentifier.headerTableSize
            ret += headerTableSize
        }

        if enablePush {
            ret += SettingsIdentifier.enablePush
            ret.append(enablePush ? 1 : 0)
        }

        if let maxConcurrentStreams = maxConcurrentStreams {
            ret += SettingsIdentifier.maxConcurrentStreams
            ret += maxConcurrentStreams
        }

        if let initialWindowSize = initialWindowSize {
            ret += SettingsIdentifier.initialWindowSize
            ret += initialWindowSize
        }

        if let maxFrameSize = maxFrameSize {
            ret += SettingsIdentifier.maxFrameSize
            ret += maxFrameSize
        }

        if let maxHeaderListSize = maxHeaderListSize {
            ret += SettingsIdentifier.maxHeaderListSize
            ret += maxHeaderListSize
        }

        frameLength = ret.encodeFrameLength()

        // Settings frames must have a length which is a multiple of 6 octets
        if frameLength % 6 != 0 || frameLength == 0 {
            throw Http2Error.frameSize
        }

        return ret
    }
}

extension SettingsFrame: HasFlags {
    internal func setFlags() throws {
        if ack {
            flags.formUnion(.ack)
        }
    }
}
