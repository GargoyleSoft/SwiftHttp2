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

public protocol HasHeaders: class {
    var headerFieldIndexType: Http2HeaderFieldIndexType { get set }
    var headerEncoding: Http2HeaderStringEncodingType { get set }
    var endHeaders: Bool { get set }
    var headers: [Http2HeaderEntry] { get set }

    func add(header: Http2HeaderEntry)
    func add(headers: [Http2HeaderEntry])
    func add(header field: String, value: String, indexing: Http2HeaderFieldIndexType)
}

extension HasHeaders where Self: AbstractFrame {
    /// Adds a header to the frame.
    ///
    /// - Parameter header: The header field and value to add.
    public func add(header: Http2HeaderEntry) {
        headers.append(header)
    }

    /// Adds a set of headers to the frame.
    ///
    /// - Parameter headers: The header field/value pairs to add.
    public func add(headers: [Http2HeaderEntry]) {
        self.headers.append(contentsOf: headers)
    }

    /// Adds a header to the frame.
    ///
    /// - Parameters:
    ///   - field: The name of the header field.
    ///   - value: The value of the header.
    public func add(header field: String, value: String, indexing: Http2HeaderFieldIndexType = .literalHeaderNone) {
        headers.append(Http2HeaderEntry(field: field, value: value, indexing: indexing))
    }

    /// Encodes the headers via HPACK/RFC7541
    ///
    /// - Returns: The HPACK encoded headers.
    public func encodeHeaders() -> [UInt8] {
        if headers.isEmpty {
            return []
        } else {
            return headerEncoder.encode(headers: headers, indexing: headerFieldIndexType)
        }
    }

    internal func decodeHeaders(data: [UInt8], endIndex: Int) throws {
        guard endIndex > decodeIndex else {
            headers = []
            return
        }

        headers = try headerDecoder.decode(encoded: Array(data[decodeIndex ..< endIndex]))
    }
}

protocol HasFlags {
    func setFlags() throws
}

protocol HasFramePriority: class {
    var dependsOn: Http2Stream? { get set }
    var dependsOnStreamExclusively: Bool { get set }
    var priorityWeight: UInt8 { get set }

    func addPriority(dependsOn: Http2Stream, exclusive: Bool, weight: UInt8)
    func removePriority()
}

extension HasFramePriority where Self: AbstractFrame {
    internal func encodePriority() throws -> [UInt8] {
        var ret: [UInt8] = []
        guard flags.contains(.priority) else {
            return []
        }
        
        guard let dependsOn = dependsOn else {
            throw FrameCodingError.missingDependsOnStream
        }

        var data = dependsOn.identifier
        if dependsOnStreamExclusively {
            data |= 1 << 31
        } else {
            data &= ~(1 << 31)
        }

        ret += data

        if priorityWeight > 0 {
            ret.append(priorityWeight - 1)
        } else {
            ret.append(0)
        }

        return ret
    }

    internal func decodePriority(data: [UInt8]) throws {
        defer { decodeIndex += 5 }

        let identifier = UInt32(bytes: data, startIndex: decodeIndex)
        if let stream = Http2StreamCache.shared.stream(with: identifier) {
            dependsOn = stream
        } else {
            dependsOn = Http2Stream.connectionStream
        }

        dependsOnStreamExclusively = (identifier & 0x80000000) == 0x80000000

        // TODO: This will throw if the weight is 255 because 256 is outside the bounds of a UInt8
        priorityWeight = data[decodeIndex + 4] + 1
    }

    /// Adds the PRIORITY flag to the frame.
    ///
    /// - Parameters:
    ///   - dependsOn: The stream that this frame is dependent upon.
    ///   - exclusive: Whether or not the stream dependency is exclusive.
    ///   - weight: The priority weight for the stream, between 0 and 255.
    func addPriority(dependsOn: Http2Stream, exclusive: Bool, weight: UInt8) {
        self.dependsOn = dependsOn
        self.dependsOnStreamExclusively = exclusive
        self.priorityWeight = weight
        self.flags.formUnion(.priority)
    }

    /// Removes the PRIORITY flag from the frame.
    func removePriority() {
        self.flags.remove(.priority)
        self.dependsOn = nil
    }
}

protocol HasPadding : class {
    var padLength: UInt8 { get set }
    var padding: [UInt8]? { get set }
}

extension HasPadding where Self: AbstractFrame {
    internal func initialize(padding: [UInt8]?, length: UInt8) throws {
        if let padding = padding {
            guard padding.count <= UInt8.max else {
                throw PaddingError.paddingTooLarge
            }

            self.padding = padding
            self.padLength = UInt8(padding.count)
        } else if length > 0 {
            self.padLength = length
            self.padding = (1...length).map { _ in
                UInt8(arc4random_uniform(UInt32(UInt8.max)))
            }
        }

        // setFlags was called by the concrete class' initializer, but the
        // call to initializePadding has to come *after* the super initializer,
        // so it's a chicken and egg problem.  Since we have padding we know we
        // are also "HasFlags" and thus we need to just call setFlags manually
        // since we changed things.
        try (self as! HasFlags).setFlags()
    }

    internal func decodePadLengthIfNecessary(data: UInt8) {
        guard flags.contains(.padded) else { return }

        padLength = data
        decodeIndex += 1
    }

    internal func decodePaddingIfNecessary(data: [UInt8], from: Int) -> [UInt8]? {
        guard from < data.endIndex else {
            return nil
        }

        return [UInt8](data[from...])
    }

    internal func encodePadLengthIfNecessary() -> [UInt8] {
        if flags.contains(.padded) {
            return [padLength]
        } else {
            return []
        }
    }

    internal func encodePaddingIfNecessary() throws -> [UInt8] {
        if flags.contains(.padded) {
            return padding!
        } else {
            return []
        }
    }
}
