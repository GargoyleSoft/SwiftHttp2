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

/// GOAWAY frames are used to initiate shutdown of a connection or to signal serious error conditions.
/// https://tools.ietf.org/html/rfc7540#section-6.8
public final class GoAwayFrame: AbstractFrame {
    /// The highest numbered stream identifier for which the sender might have (or will) take action on.
    /// - note: If this is `nil` then the stream identified is not recognized by the receiver.
    public var lastStream: Http2Stream? = nil

    /// The reason for closing the connection.
    public var errorCode = Http2ErrorCode.none

    /// Additional debug data for diagnostic purposes.
    public var debugData: [UInt8]? = nil

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - lastStream: The highest numbered stream identifier for which the sender *might* have taken
    ///                 some action on or might yet take action on.  Set to 0 if no streams were processed.
    ///   - errorCode: The reason for closing the connection.  Defaults to `.none`
    ///   - debugData: Additional debug data for diagnostic purposes.
    public init(lastStream: Http2Stream, errorCode: Http2ErrorCode = .none, debugData: [UInt8]? = nil) {
        self.lastStream = lastStream
        self.errorCode = errorCode
        self.debugData = debugData

        super.init(type: .goAway, stream: Http2Stream.connectionStream)
    }

    /// Convenience initializer allowing `String` `debugData` to be provided
    ///
    /// - Parameters:
    ///   - lastStream: The highest numbered stream identifier for which the sender *might* have taken
    ///                 some action on or might yet take action on.  Set to 0 if no streams were processed.
    ///   - errorCode: The reason for closing the connection.  Defaults to `.none`
    ///   - debugData: Additional debug data for diagnostic purposes.
    convenience init(lastStream: Http2Stream, errorCode: Http2ErrorCode = .none, debugData: String) {
        self.init(lastStream: lastStream, errorCode: errorCode, debugData: [UInt8](debugData.utf8))
    }

    override internal init(data: [UInt8]) throws {
        try super.init(data: data)

        let identifier = UInt32(bytes: data, startIndex: decodeIndex)
        lastStream = Http2StreamCache.shared.stream(with: identifier)
        decodeIndex += 4

        guard let error = Http2ErrorCode(rawValue: UInt32(bytes: data, startIndex: decodeIndex)) else {
            throw FrameCodingError.invalidErrorCode
        }

        errorCode = error
        decodeIndex += 4

        guard decodeIndex < data.endIndex else {
            return
        }

        debugData = [UInt8](data[decodeIndex...])
    }

    /// Encodes the frame into a set of `UInt8` bytes.
    ///
    /// - Returns: The encoded frame data.
    /// - Throws: Various errors possible.
    override public func encode() throws -> [UInt8] {
        var ret = try super.encode()
        ret += lastStream!.identifier
        ret += errorCode

        if let debugData = debugData {
            ret += [UInt8](debugData)
        }

        frameLength = ret.encodeFrameLength()
        
        return ret
    }
}
