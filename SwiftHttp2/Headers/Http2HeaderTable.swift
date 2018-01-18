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

/// A alias representing a header's field name and value.
public typealias Http2HeaderTableEntry = (field: String, value: String)

internal struct Http2HeaderTable {
    internal let staticTableCount: Int

    private let staticTable: [Http2HeaderTableEntry] = [
        (":authority", ""),
        (":method", "GET"),
        (":method", "POST"),
        (":path", "/"),
        (":path", "/index.html"),
        (":scheme", "http"),
        (":scheme", "https"),
        (":status", "200"),
        (":status", "204"),
        (":status", "206"),
        (":status", "304"),
        (":status", "400"),
        (":status", "404"),
        (":status", "500"),
        ("accept-charset", ""),
        ("accept-encoding", "gzip, deflate"),
        ("accept-language", ""),
        ("accept-ranges", ""),
        ("accept", ""),
        ("access-control-allow-origin", ""),
        ("age", ""),
        ("allow", ""),
        ("authorization", ""),
        ("cache-control", ""),
        ("content-disposition", ""),
        ("content-encoding", ""),
        ("content-language", ""),
        ("content-length", ""),
        ("content-location", ""),
        ("content-range", ""),
        ("content-type", ""),
        ("cookie", ""),
        ("date", ""),
        ("etag", ""),
        ("expect", ""),
        ("expires", ""),
        ("from", ""),
        ("host", ""),
        ("if-match", ""),
        ("if-modified-since", ""),
        ("if-none-match", ""),
        ("if-range", ""),
        ("if-unmodified-since", ""),
        ("last-modified", ""),
        ("link", ""),
        ("location", ""),
        ("max-forwards", ""),
        ("proxy-authenticate", ""),
        ("proxy-authorization", ""),
        ("range", ""),
        ("referer", ""),
        ("refresh", ""),
        ("retry-after", ""),
        ("server", ""),
        ("set-cookie", ""),
        ("strict-transport-security", ""),
        ("transfer-encoding", ""),
        ("user-agent", ""),
        ("vary", ""),
        ("via", ""),
        ("www-authenticate", ""),
        ]


    /// If a SETTINGS frame comes in with the SETTINGS_HEADER_TABLE_SIZE set this variable
    var settingsHeaderTableSize = 4096 {
        didSet {
            if maxDynamicTableSize > settingsHeaderTableSize {
                maxDynamicTableSize = settingsHeaderTableSize
            }
        }
    }

    // According to https://tools.ietf.org/html/rfc7541#section-4.2 an encoder can choose
    // to use less than settingsHeaderTableSize if it wants to.  That's why there are two
    // separate variables for the table size.
    var maxDynamicTableSize: Int {
        didSet {
            if maxDynamicTableSize == 0 {
                dynamicTable.removeAll()
                maxDynamicTableSize = 4096
                return
            }

            while dynamicTableSize() > maxDynamicTableSize {
                _ = dynamicTable.popLast()
            }
        }
    }

    internal var dynamicTable: [Http2HeaderTableEntry] = []

    init() {
        staticTableCount = staticTable.count
        maxDynamicTableSize = settingsHeaderTableSize
    }

    func dumpTableForUnitTests() {
        print("Dynamic Table:")

        for (idx, header) in dynamicTable.enumerated() {
            print(String(format: "[%3d] (s = %d): \(header.field): \(header.value)", idx + 1, header.field.count + header.value.count + 32))
        }
        print("      Table size: \(dynamicTableSize())")
    }

    func dynamicTableSize() -> Int {
        return dynamicTable
            .map {
                $0.field.count + $0.value.count + 32
            }
            .reduce(0, +)
    }

    func indexOf(field: String, value: String? = nil) -> Int? {
        let comparer: (Http2HeaderTableEntry) -> Bool

        if let value = value {
            comparer = {
                return $0.field.caseInsensitiveCompare(field) == .orderedSame &&
                    $0.value == value
            }
        } else {
            comparer = { $0.field.caseInsensitiveCompare(field) == .orderedSame }
        }

        if let index = staticTable.index(where: comparer) {
            return index + 1
        }

        if let index = dynamicTable.index(where: comparer) {
            return staticTableCount + index + 1
        }

        return nil
    }

    mutating func add(field: String, value: String) {
        let entrySize = field.count + value.count + 32

        guard entrySize <= maxDynamicTableSize else {
            dynamicTable.removeAll()
            return
        }

        while dynamicTableSize() + entrySize > maxDynamicTableSize {
            _ = dynamicTable.popLast()
        }

        dynamicTable.insert((field: field.lowercased(), value: value), at: 0)
    }

    subscript(index: Int) -> Http2HeaderTableEntry? {
        get {
            guard index > 0 else { return nil }

            if index <= staticTableCount {
                return staticTable[index - 1]
            }

            let dynamicTableIndex = index - staticTableCount
            if dynamicTableIndex <= dynamicTable.count {
                return dynamicTable[dynamicTableIndex - 1]
            }

            return nil
        }
    }
}
