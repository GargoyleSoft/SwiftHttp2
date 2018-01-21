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

internal struct Http2HeaderTable {
    internal let staticTableCount: Int

    private let staticTable: [Http2HeaderEntry] = [
        Http2HeaderEntry(field: ":authority"),
        Http2HeaderEntry(field: ":method", value: "GET"),
        Http2HeaderEntry(field: ":method", value: "POST"),
        Http2HeaderEntry(field: ":path", value: "/"),
        Http2HeaderEntry(field: ":path", value: "/index.html"),
        Http2HeaderEntry(field: ":scheme", value: "http"),
        Http2HeaderEntry(field: ":scheme", value: "https"),
        Http2HeaderEntry(field: ":status", value: "200"),
        Http2HeaderEntry(field: ":status", value: "204"),
        Http2HeaderEntry(field: ":status", value: "206"),
        Http2HeaderEntry(field: ":status", value: "304"),
        Http2HeaderEntry(field: ":status", value: "400"),
        Http2HeaderEntry(field: ":status", value: "404"),
        Http2HeaderEntry(field: ":status", value: "500"),
        Http2HeaderEntry(field: "accept-charset"),
        Http2HeaderEntry(field: "accept-encoding", value: "gzip, deflate"),
        Http2HeaderEntry(field: "accept-language"),
        Http2HeaderEntry(field: "accept-ranges"),
        Http2HeaderEntry(field: "accept"),
        Http2HeaderEntry(field: "access-control-allow-origin"),
        Http2HeaderEntry(field: "age"),
        Http2HeaderEntry(field: "allow"),
        Http2HeaderEntry(field: "authorization"),
        Http2HeaderEntry(field: "cache-control"),
        Http2HeaderEntry(field: "content-disposition"),
        Http2HeaderEntry(field: "content-encoding"),
        Http2HeaderEntry(field: "content-language"),
        Http2HeaderEntry(field: "content-length"),
        Http2HeaderEntry(field: "content-location"),
        Http2HeaderEntry(field: "content-range"),
        Http2HeaderEntry(field: "content-type"),
        Http2HeaderEntry(field: "cookie"),
        Http2HeaderEntry(field: "date"),
        Http2HeaderEntry(field: "etag"),
        Http2HeaderEntry(field: "expect"),
        Http2HeaderEntry(field: "expires"),
        Http2HeaderEntry(field: "from"),
        Http2HeaderEntry(field: "host"),
        Http2HeaderEntry(field: "if-match"),
        Http2HeaderEntry(field: "if-modified-since"),
        Http2HeaderEntry(field: "if-none-match"),
        Http2HeaderEntry(field: "if-range"),
        Http2HeaderEntry(field: "if-unmodified-since"),
        Http2HeaderEntry(field: "last-modified"),
        Http2HeaderEntry(field: "link"),
        Http2HeaderEntry(field: "location"),
        Http2HeaderEntry(field: "max-forwards"),
        Http2HeaderEntry(field: "proxy-authenticate"),
        Http2HeaderEntry(field: "proxy-authorization"),
        Http2HeaderEntry(field: "range"),
        Http2HeaderEntry(field: "referer"),
        Http2HeaderEntry(field: "refresh"),
        Http2HeaderEntry(field: "retry-after"),
        Http2HeaderEntry(field: "server"),
        Http2HeaderEntry(field: "set-cookie"),
        Http2HeaderEntry(field: "strict-transport-security"),
        Http2HeaderEntry(field: "transfer-encoding"),
        Http2HeaderEntry(field: "user-agent"),
        Http2HeaderEntry(field: "vary"),
        Http2HeaderEntry(field: "via"),
        Http2HeaderEntry(field: "www-authenticate"),
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
                maxDynamicTableSize = settingsHeaderTableSize
                return
            } else if maxDynamicTableSize > settingsHeaderTableSize {
                maxDynamicTableSize = settingsHeaderTableSize
            }

            while dynamicTableSize() > maxDynamicTableSize {
                _ = dynamicTable.popLast()
            }
        }
    }

    internal var dynamicTable: [Http2HeaderEntry] = []

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
        let comparer: (Http2HeaderEntry) -> Bool

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

    mutating func add(field: String, value: String, indexing: Http2HeaderFieldIndexType = .literalHeaderNone) {
        let entrySize = field.count + value.count + 32

        guard entrySize <= maxDynamicTableSize else {
            dynamicTable.removeAll()
            return
        }

        while dynamicTableSize() + entrySize > maxDynamicTableSize {
            _ = dynamicTable.popLast()
        }

        dynamicTable.insert(Http2HeaderEntry(field: field.lowercased(), value: value), at: 0)
    }

    subscript(index: Int) -> Http2HeaderEntry? {
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
