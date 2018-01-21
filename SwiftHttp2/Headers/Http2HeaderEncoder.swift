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

/// The type of HPACK encoding to use.
///
/// - literalOctets: Use string literals.
/// - huffmanCode: Use Huffman Codes.
public enum Http2HeaderStringEncodingType {
    case literalOctets
    case huffmanCode
}

/// The type of header indexing to use.
///
/// - incremental: Adds headers to the dynamic table.
/// - none: Adds headers without altering the dynamic header table.
/// - never: Adds headers without altering the dynamic header table.  Used for protecting values.
public enum Http2HeaderFieldIndexType {
    case indexedHeader
    case literalHeaderIncremental
    case literalHeaderNone
    case literalHeaderNever
}

/// The class used to encode HTTP/2 headers according to RFC7541
/// - See: https://tools.ietf.org/html/rfc7541
public final class Http2HeaderEncoder {
    internal var headerTable = Http2HeaderTable()

    /// The default type of string encoding to use.  `.huffmanCode` is the default.
    public var defaultStringEncoding: Http2HeaderStringEncodingType

    /// The default type of header indexing to use.  `.incremental` is the default.
    public var defaultIndexing: Http2HeaderFieldIndexType

    /// The designated initializer.
    ///
    /// - Parameters
    ///   - indexing: The type of header indexing to use.  Defaults to `.incremental`
    ///   - stringEncoding: The type of string encoding to use.  Defaults to `.huffmanCode`
    public init(indexing: Http2HeaderFieldIndexType = .literalHeaderIncremental, stringEncoding: Http2HeaderStringEncodingType = .huffmanCode) {
        self.defaultStringEncoding = stringEncoding
        self.defaultIndexing = indexing
    }

    /// Encodes a set of headers for a HEADERS or CONTINUATION frame.
    ///
    /// - Parameters:
    ///   - headers: The headers to encode.
    ///   - indexing: The type of header indexing to use.  Defaults to `.none`
    ///   - stringEncoding: The type of string encoding to use.  Defaults to `.huffmanCode`
    /// - Warning: Do not use this class method unless you will never encode another header during the entire *connection*.
    /// - Returns: The encoded headers.
    public class func encode(headers: [Http2HeaderEntry], indexing: Http2HeaderFieldIndexType = .literalHeaderNone, using stringEncoding: Http2HeaderStringEncodingType = .huffmanCode) -> [UInt8] {
        let encoder = Http2HeaderEncoder(stringEncoding: stringEncoding)
        return encoder.encode(headers: headers, indexing: indexing, using: stringEncoding)
    }

    // Shouldn't be sending just one header in production, but this is useful for unit tests.
    internal class func encode(field: String, value: String, indexing: Http2HeaderFieldIndexType = .literalHeaderNone, using stringEncoding: Http2HeaderStringEncodingType = .huffmanCode) -> [UInt8] {
        let encoder = Http2HeaderEncoder(stringEncoding: stringEncoding)
        return encoder.encode(headers:[Http2HeaderEntry(field: field, value: value, indexing: indexing)])
    }

    /// Encodes a set of field/value headers into HPACK format according to RFC7541.
    ///
    /// - Parameters:
    ///   - headers: An array of headers to encode.
    ///   - indexing: The type of indexing to use.  If not specified, the `defaultIndexing` of the encoder is used.
    ///   - stringEncoding: Whether to use literal octets or Huffman codes.  If not specified, the `defaultStringEncoding` is used.
    /// - Returns: The encoded headers.
    public func encode(headers: [Http2HeaderEntry], indexing: Http2HeaderFieldIndexType? = nil, using stringEncoding: Http2HeaderStringEncodingType? = nil) -> [UInt8] {
        return headers
            .filter {
                $0.value.isEmpty == false
            }
            .map {
                encode(field: $0.field, value: $0.value, indexing: $0.indexing ?? indexing ?? self.defaultIndexing, using: stringEncoding ?? self.defaultStringEncoding)
            }
            .reduce([], +)
    }

    /// Encode a header field name and value into HPACK format according to RFC7541.
    ///
    /// - Parameters:
    ///   - field: The name of the header field.
    ///   - value: The value of the header field.
    ///   - indexing: What type of indexing to use.  If not specified, the `defaultIndexing` of the encoder is used.
    ///   - stringEncoding: Whether to use literal octets or Huffman codes.  If not specified, the `defaultStringEncoding` is used.
    /// - Returns: The encoded header
    public func encode(field uppercaseField: String, value: String, indexing: Http2HeaderFieldIndexType? = nil, using stringEncoding: Http2HeaderStringEncodingType? = nil) -> [UInt8] {
        let lowercaseField = uppercaseField.lowercased()

        if let fieldIndex = headerTable.indexOf(field: lowercaseField, value: value) {
            // The RFC is confusing but if the field AND value match, then it's an Indexed Header Field Representation
            // https://tools.ietf.org/html/rfc7541#section-6.1
            var encoded = encode(fieldIndex, prefixBits: 7)
            encoded[0] |= 0b1000_0000
            return encoded
        }

        // Otherwise, it's one of the Literal Header Field Representations
        // https://tools.ietf.org/html/rfc7541#section-6.2

        let startBits: UInt8
        let prefixBits: Int

        switch indexing ?? self.defaultIndexing {
        case .literalHeaderIncremental:
            startBits = 0b100_0000
            prefixBits = 6

        case .literalHeaderNever:
            startBits = 0b1_0000
            prefixBits = 4

        case .literalHeaderNone:
            startBits = 0
            prefixBits = 4

        case .indexedHeader:
            fatalError("Should not have gotten here!")
        }

        var ret: [UInt8]

        if let fieldIndex = headerTable.indexOf(field: lowercaseField) {
            ret = encode(fieldIndex, prefixBits: prefixBits)
            ret[0] |= startBits
        } else {
            ret = [startBits]
            ret.append(contentsOf: encode(lowercaseField, using: stringEncoding ?? self.defaultStringEncoding))
        }

        ret.append(contentsOf: encode(value, using: stringEncoding ?? self.defaultStringEncoding))

        if indexing == .literalHeaderIncremental {
            // Don't add this in the switch above or it'll run before the header lookup
            // which would make it always "succeed"
            headerTable.add(field: lowercaseField, value: value)
        }

        return ret
    }

    internal func encode(_ orig: Int, prefixBits: Int) -> [UInt8] {
        let max = Int(pow(Double(2), Double(prefixBits))) - 1

        guard orig >= max else { return [UInt8(orig)] }

        var ret: [UInt8] = [UInt8(max)]
        var value = orig - max

        while value >= 128 {
            ret.append(UInt8(value % 128) + 128)
            value /= 128
        }

        ret.append(UInt8(value))

        return ret
    }

    private func encode(_ value: String, using stringEncoding: Http2HeaderStringEncodingType) -> [UInt8] {
        if stringEncoding == .literalOctets {
            return encodeAsStringLiteral(value: value)
        } else {
            return encodeAsHuffmanCode(value: value)
        }
    }

    private func encodeAsStringLiteral(value: String) -> [UInt8] {
        return encode(value.count, prefixBits: 7) + value.utf8
    }

    private func encodeAsHuffmanCode(value: String) -> [UInt8] {
        let encoded = Huffman.encode(value: value)

        var ret = encode(encoded.count, prefixBits: 7)
        ret[0] |= 0b1000_0000

        return ret + encoded
    }
}

