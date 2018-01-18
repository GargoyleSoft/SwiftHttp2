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

/// PRIORITY frames specify the *advised* priority of a stream.
/// - See: https://tools.ietf.org/html/rfc7540#section-6.3
final public class PriorityFrame: AbstractFrame, HasFramePriority {
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
    ///   - dependsOn: The stream that this frame is dependent upon.
    ///   - dependsOnStreamExclusively: Whether or not the stream dependency is exclusive.
    ///   - priorityWeight: The priority weight for the stream, between 0 and 255.
    public init(stream: Http2Stream, dependsOn: Http2Stream? = nil, dependsOnStreamExclusively: Bool = false, priorityWeight: UInt8 = 0) {
        self.dependsOn = dependsOn
        self.dependsOnStreamExclusively = dependsOnStreamExclusively
        self.priorityWeight = priorityWeight

        super.init(type: .priority, stream: stream)
    }

    override internal init(data: [UInt8]) throws {
        try super.init(data: data)

        guard stream != Http2Stream.connectionStream else {
            throw Http2Error.protocolError
        }
        
        try decodePriority(data: data)
    }

    /// Encodes the frame into a set of `UInt8` bytes.
    ///
    /// - Returns: The encoded frame data.
    /// - Throws: Various errors possible.
    override public func encode() throws -> [UInt8] {
        // The HasFramePriority protocol requires the dependsOn to be nillable.
        // However, the PriorityFrame *requires* the items.
        guard let _ = dependsOn else {
            throw FrameCodingError.missingDependsOnStream
        }

        var ret = try super.encode()

        // Fake out having the priority flag so things get set.  However, the PRIORITY frame
        // does not define flags, so make sure that they aren't left on the packet.
        flags.formUnion(.priority)
        ret += try encodePriority()
        flags.remove(.priority)

        frameLength = ret.encodeFrameLength()

        guard frameLength == 5 else {
            throw Http2Error.frameSize
        }

        return ret
    }
}


