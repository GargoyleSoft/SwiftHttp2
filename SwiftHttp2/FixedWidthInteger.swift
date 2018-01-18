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

internal extension FixedWidthInteger {
    func toByteArray() -> [UInt8] {
        let size = MemoryLayout<Self>.size

        // Network byte order is always big endian
        var bytes = self.bigEndian

        let ptr = withUnsafePointer(to: &bytes) {
            $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                UnsafeBufferPointer(start: $0, count: size)
            }
        }

        return [UInt8](ptr)
    }
}

internal extension UnsignedInteger {
    init(bytes: [UInt8], startIndex: Int, bigEndian: Bool = true) {
        var s: Self = 0

        let width = MemoryLayout<Self>.size
        let endIndex = startIndex + width

        for (i, byte) in bytes[startIndex ..< endIndex].enumerated() {
            let shiftAmount = (bigEndian ? (width - 1 - i) : i) * 8
            s |= Self(truncatingIfNeeded: byte) << shiftAmount
        }

        self = s
    }
}

internal extension Array where Iterator.Element == UInt8 {
    mutating func encodeFrameLength() -> UInt32 {
        // Frame length doesn't include the frame header
        let l = self.count - AbstractFrame.frameHeaderLength

        // Network byte order is always big endian
        self[0] = UInt8((l >> 16) & 0xFF)
        self[1] = UInt8((l >> 8) & 0xFF)
        self[2] = UInt8(l & 0xFF)

        return UInt32(truncatingIfNeeded: l)
    }

    func toString() -> String? {
        return String(bytes: self, encoding: .utf8)
    }
}

internal func +=<T>(lhs: inout [UInt8], rhs: T) where T : FixedWidthInteger & UnsignedInteger {
    lhs += rhs.toByteArray()
}


