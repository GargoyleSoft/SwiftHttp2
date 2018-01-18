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

/// Errors which can occur during header decoding
///
/// - invalidHeaderBlock: The header block is invalid.
/// - missingData: The data block is missing.
/// - invalidTableIndex: The table index is invalid.
/// - invalidTableSizeUpdate: The udpated table size is not valid.
public enum Http2DecoderError: Error {
    case invalidHeaderBlock
    case missingData
    case invalidTableIndex(Int)
    case invalidTableSizeUpdate(asked: Int, max: Int)
}

/// Used to decode an HTTP/2 header as defined by RFC7541
/// - See: https://tools.ietf.org/html/rfc7541
public final class Http2HeaderDecoder {
    internal var headerTable = Http2HeaderTable()
    internal var headers: [Http2HeaderTableEntry] = []

    private var encodedData: [UInt8] = []
    private var index: Int = 0

    internal init() {
    }

    internal func decode(encoded data: [UInt8]) throws -> [Http2HeaderTableEntry] {
        guard !data.isEmpty else { throw Http2DecoderError.missingData }

        headers = []
        
        encodedData = data

        index = data.startIndex

        while index != data.endIndex {
            let byte = data[index]

            if byte & 0b1000_0000 == 0b1000_0000 {
                // Indexed Header Field Representation https://tools.ietf.org/html/rfc7541#section-6.1
                let index = decodeInteger(prefixBits: 7)
                guard let entry = headerTable[index] else {
                    throw Http2DecoderError.invalidTableIndex(index)
                }

                headers.append(entry)
            } else if byte & 0b1100_0000 == 0b0100_0000 {
                // Literal header Field with Incremental Indexing https://tools.ietf.org/html/rfc7541#section-6.2.1
                let entry = try decodeLiteralHeaderField(prefixBits: 6)
                headers.append(entry)
                headerTable.add(field: entry.field, value: entry.value)
            } else if byte & 0b1111_0000 == 0 {
                // Literal Header Field without Indexing https://tools.ietf.org/html/rfc7541#section-6.2.2
                let entry = try decodeLiteralHeaderField(prefixBits: 4)
                headers.append(entry)
            } else if byte & 0b1111_0000 == 0b1_0000 {
                // Literal Header Field never Indexed https://tools.ietf.org/html/rfc7541#section-6.2.3
                let entry = try decodeLiteralHeaderField(prefixBits: 4)
                headers.append(entry)
            } else if byte & 0b1110_0000 == 0b10_0000 {
                // Dynamic Table Size Update https://tools.ietf.org/html/rfc7541#section-6.3
                let size = decodeInteger(prefixBits: 5)
                if size > headerTable.settingsHeaderTableSize {
                    throw Http2DecoderError.invalidTableSizeUpdate(asked: size, max: headerTable.settingsHeaderTableSize)
                }

                headerTable.maxDynamicTableSize = size
            } else {
                throw Http2DecoderError.invalidHeaderBlock
            }
        }

        return headers
    }

    private func decodeLiteralHeaderField(prefixBits: UInt8) throws -> Http2HeaderTableEntry {
        let index = decodeInteger(prefixBits: prefixBits)

        let field: String
        if index == 0 {
            field = decodeString()
        } else if let entry = headerTable[index] {
            field = entry.field
        } else {
            throw Http2DecoderError.invalidTableIndex(index)
        }

        return (field, decodeString())
    }

    private func decodeString() -> String {
        let huffman = encodedData[index] & 0b1000_0000 == 0b1000_0000

        let length = decodeInteger(prefixBits: 7)

        defer { index += length }

        let bytes = Array(encodedData[index ..< index + length])

        if huffman {
            return Huffman.decode(data: bytes)
        } else {
            return String(cString: bytes)
        }
    }

    internal func decodeInteger(prefixBits: UInt8) -> Int {
        let max = Int(pow(Double(2), Double(prefixBits))) - 1
        let mask: (UInt8) = 0xFF >> (8 - prefixBits)
        var value = Int(encodedData[index] & mask)

        if value < max {
            index += 1
            return value
        }

        var nextOctet: Int

        var M = 0
        repeat {
            index += 1

            nextOctet = Int(encodedData[index])
            value += (nextOctet & 127) * Int(pow(Double(2), Double(M)))

            M += 7
        } while nextOctet & 128 == 128

        return value
    }
}
