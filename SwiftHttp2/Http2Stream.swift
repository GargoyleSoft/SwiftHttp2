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

/// The state the stream is current in.
///
/// - idle: All streams start in the idle state.
/// - reservedLocal: A stream which has been promised by sending a PUSH_PROMISE frame.
/// - reservedRemote: A stream which has been reserved by a remote peer.
/// - open: An active stream able to be used to send frames of any type.
/// - halfClosedLocal: Only able to send WINDOW_UPDATE, PRIORITY and RST_STREAM
/// - halfClosedRemote: The stream is no longer being used by the peer to send frames.
/// - closed: The stream is terminated.
public enum StreamState {
    case idle
    case reservedLocal
    case reservedRemote
    case open
    case halfClosedLocal
    case halfClosedRemote
    case closed
}

/// Possible error types for `Http2Stream` operations.
///
/// - identifierTooLarge: The identifier for the stream is too large.
/// - alreadyExists: The requested stream already exists.
/// - tooManyStreams: Too many stream are open.
public enum StreamError : Error {
    case identifierTooLarge
    case alreadyExists
    case tooManyStreams
}

/// Represents a connection to a remote peer.
final public class Http2Stream: Equatable {
    public static func ==(lhs: Http2Stream, rhs: Http2Stream) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    internal static let connectionStream = try! Http2Stream(identifier: 0)

    /// The identifier of the stream.
    public let identifier: UInt32

    private var frames: [AbstractFrame] = []

    /// The `StreamState` of the `Http2Stream`
    public internal(set) var state = StreamState.idle

    /// Whether or not this is the `Http2Stream` representing the connection, vs. a specifc `Http2Stream`
    public var isConnectionStream: Bool {
        return identifier == 0
    }

    // Only StreamCache should be creating streams which is why they are
    // both in the same file and I'm using the horrible 'fileprivate' keyword here.
    fileprivate init(identifier: UInt32) throws {
        guard identifier < 0b10000000_00000000_00000000_00000000 else {
            throw StreamError.identifierTooLarge
        }

        self.identifier = identifier
    }
}

/// A cache to use for creating and finding `Http2Stream` objects.
final public class Http2StreamCache {
    internal enum StreamCacheType {
        case client, server
    }

    /// The shared instance to use.
    static public let shared = Http2StreamCache()

    private var maxStreamIdentifier: UInt32 = 0
    private var cache: [UInt32 : Http2Stream] = [:]

    private init() {}

    internal func initialize(as type: StreamCacheType) {
        cache = [:]
        maxStreamIdentifier = type == .client ? 1 : 2
    }

    /// Gets the list of streams in numeric order.
    ///
    /// - Returns: An array of `Http2Stream` objects.
    public func orderedStreams() -> [Http2Stream] {
        return cache
            .sorted { $0.key < $1.key }
            .map { $0.value }
    }
    
    /// Finds the specified stream.
    ///
    /// - Parameter identifier: The numerical identifier for the `Http2Stream`
    /// - Returns: The stream, or `nil` if it does not exist.
    public func stream(with identifier: UInt32) -> Http2Stream? {
        return cache[identifier & ~(1 << 31)]
    }

    /// Creates a new stream.  The next valid stream index is automatically used.
    ///
    /// - Returns: An `Http2Stream` object in the default (`.idle`) state.
    /// - Throws: `StreamError`
    public func createStream() throws -> Http2Stream {
        maxStreamIdentifier += 2

        guard let stream = try? Http2Stream(identifier: maxStreamIdentifier) else {
            maxStreamIdentifier -= 2
            throw StreamError.tooManyStreams
        }

        cache[maxStreamIdentifier] = stream

        return stream
    }

    internal func createStream(with identifier: UInt32) throws -> Http2Stream {
        let ident = identifier & ~(1 << 31)

        guard cache[ident] == nil else {
            throw StreamError.alreadyExists
        }

        let stream = try Http2Stream(identifier: ident)
        cache[ident] = stream

        return stream
    }
}

