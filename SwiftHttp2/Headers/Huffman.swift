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

typealias HuffmanDataEntry = (hex: Int, count: Int)

final class Huffman {
    // https://tools.ietf.org/html/rfc7541#appendix-B
    private static let data: [HuffmanDataEntry] = [
        (hex: 0x1ff8, count: 13),
        (hex: 0x7fffd8, count: 23),
        (hex: 0xfffffe2, count: 28),
        (hex: 0xfffffe3, count: 28),
        (hex: 0xfffffe4, count: 28),
        (hex: 0xfffffe5, count: 28),
        (hex: 0xfffffe6, count: 28),
        (hex: 0xfffffe7, count: 28),
        (hex: 0xfffffe8, count: 28),
        (hex: 0xffffea, count: 24),
        (hex: 0x3ffffffc, count: 30),
        (hex: 0xfffffe9, count: 28),
        (hex: 0xfffffea, count: 28),
        (hex: 0x3ffffffd, count: 30),
        (hex: 0xfffffeb, count: 28),
        (hex: 0xfffffec, count: 28),
        (hex: 0xfffffed, count: 28),
        (hex: 0xfffffee, count: 28),
        (hex: 0xfffffef, count: 28),
        (hex: 0xffffff0, count: 28),
        (hex: 0xffffff1, count: 28),
        (hex: 0xffffff2, count: 28),
        (hex: 0x3ffffffe, count: 30),
        (hex: 0xffffff3, count: 28),
        (hex: 0xffffff4, count: 28),
        (hex: 0xffffff5, count: 28),
        (hex: 0xffffff6, count: 28),
        (hex: 0xffffff7, count: 28),
        (hex: 0xffffff8, count: 28),
        (hex: 0xffffff9, count: 28),
        (hex: 0xffffffa, count: 28),
        (hex: 0xffffffb, count: 28),
        (hex: 0x14, count: 6),
        (hex: 0x3f8, count: 10),
        (hex: 0x3f9, count: 10),
        (hex: 0xffa, count: 12),
        (hex: 0x1ff9, count: 13),
        (hex: 0x15, count: 6),
        (hex: 0xf8, count: 8),
        (hex: 0x7fa, count: 11),
        (hex: 0x3fa, count: 10),
        (hex: 0x3fb, count: 10),
        (hex: 0xf9, count: 8),
        (hex: 0x7fb, count: 11),
        (hex: 0xfa, count: 8),
        (hex: 0x16, count: 6),
        (hex: 0x17, count: 6),
        (hex: 0x18, count: 6),
        (hex: 0x0, count: 5),
        (hex: 0x1, count: 5),
        (hex: 0x2, count: 5),
        (hex: 0x19, count: 6),
        (hex: 0x1a, count: 6),
        (hex: 0x1b, count: 6),
        (hex: 0x1c, count: 6),
        (hex: 0x1d, count: 6),
        (hex: 0x1e, count: 6),
        (hex: 0x1f, count: 6),
        (hex: 0x5c, count: 7),
        (hex: 0xfb, count: 8),
        (hex: 0x7ffc, count: 15),
        (hex: 0x20, count: 6),
        (hex: 0xffb, count: 12),
        (hex: 0x3fc, count: 10),
        (hex: 0x1ffa, count: 13),
        (hex: 0x21, count: 6),
        (hex: 0x5d, count: 7),
        (hex: 0x5e, count: 7),
        (hex: 0x5f, count: 7),
        (hex: 0x60, count: 7),
        (hex: 0x61, count: 7),
        (hex: 0x62, count: 7),
        (hex: 0x63, count: 7),
        (hex: 0x64, count: 7),
        (hex: 0x65, count: 7),
        (hex: 0x66, count: 7),
        (hex: 0x67, count: 7),
        (hex: 0x68, count: 7),
        (hex: 0x69, count: 7),
        (hex: 0x6a, count: 7),
        (hex: 0x6b, count: 7),
        (hex: 0x6c, count: 7),
        (hex: 0x6d, count: 7),
        (hex: 0x6e, count: 7),
        (hex: 0x6f, count: 7),
        (hex: 0x70, count: 7),
        (hex: 0x71, count: 7),
        (hex: 0x72, count: 7),
        (hex: 0xfc, count: 8),
        (hex: 0x73, count: 7),
        (hex: 0xfd, count: 8),
        (hex: 0x1ffb, count: 13),
        (hex: 0x7fff0, count: 19),
        (hex: 0x1ffc, count: 13),
        (hex: 0x3ffc, count: 14),
        (hex: 0x22, count: 6),
        (hex: 0x7ffd, count: 15),
        (hex: 0x3, count: 5),
        (hex: 0x23, count: 6),
        (hex: 0x4, count: 5),
        (hex: 0x24, count: 6),
        (hex: 0x5, count: 5),
        (hex: 0x25, count: 6),
        (hex: 0x26, count: 6),
        (hex: 0x27, count: 6),
        (hex: 0x6, count: 5),
        (hex: 0x74, count: 7),
        (hex: 0x75, count: 7),
        (hex: 0x28, count: 6),
        (hex: 0x29, count: 6),
        (hex: 0x2a, count: 6),
        (hex: 0x7, count: 5),
        (hex: 0x2b, count: 6),
        (hex: 0x76, count: 7),
        (hex: 0x2c, count: 6),
        (hex: 0x8, count: 5),
        (hex: 0x9, count: 5),
        (hex: 0x2d, count: 6),
        (hex: 0x77, count: 7),
        (hex: 0x78, count: 7),
        (hex: 0x79, count: 7),
        (hex: 0x7a, count: 7),
        (hex: 0x7b, count: 7),
        (hex: 0x7ffe, count: 15),
        (hex: 0x7fc, count: 11),
        (hex: 0x3ffd, count: 14),
        (hex: 0x1ffd, count: 13),
        (hex: 0xffffffc, count: 28),
        (hex: 0xfffe6, count: 20),
        (hex: 0x3fffd2, count: 22),
        (hex: 0xfffe7, count: 20),
        (hex: 0xfffe8, count: 20),
        (hex: 0x3fffd3, count: 22),
        (hex: 0x3fffd4, count: 22),
        (hex: 0x3fffd5, count: 22),
        (hex: 0x7fffd9, count: 23),
        (hex: 0x3fffd6, count: 22),
        (hex: 0x7fffda, count: 23),
        (hex: 0x7fffdb, count: 23),
        (hex: 0x7fffdc, count: 23),
        (hex: 0x7fffdd, count: 23),
        (hex: 0x7fffde, count: 23),
        (hex: 0xffffeb, count: 24),
        (hex: 0x7fffdf, count: 23),
        (hex: 0xffffec, count: 24),
        (hex: 0xffffed, count: 24),
        (hex: 0x3fffd7, count: 22),
        (hex: 0x7fffe0, count: 23),
        (hex: 0xffffee, count: 24),
        (hex: 0x7fffe1, count: 23),
        (hex: 0x7fffe2, count: 23),
        (hex: 0x7fffe3, count: 23),
        (hex: 0x7fffe4, count: 23),
        (hex: 0x1fffdc, count: 21),
        (hex: 0x3fffd8, count: 22),
        (hex: 0x7fffe5, count: 23),
        (hex: 0x3fffd9, count: 22),
        (hex: 0x7fffe6, count: 23),
        (hex: 0x7fffe7, count: 23),
        (hex: 0xffffef, count: 24),
        (hex: 0x3fffda, count: 22),
        (hex: 0x1fffdd, count: 21),
        (hex: 0xfffe9, count: 20),
        (hex: 0x3fffdb, count: 22),
        (hex: 0x3fffdc, count: 22),
        (hex: 0x7fffe8, count: 23),
        (hex: 0x7fffe9, count: 23),
        (hex: 0x1fffde, count: 21),
        (hex: 0x7fffea, count: 23),
        (hex: 0x3fffdd, count: 22),
        (hex: 0x3fffde, count: 22),
        (hex: 0xfffff0, count: 24),
        (hex: 0x1fffdf, count: 21),
        (hex: 0x3fffdf, count: 22),
        (hex: 0x7fffeb, count: 23),
        (hex: 0x7fffec, count: 23),
        (hex: 0x1fffe0, count: 21),
        (hex: 0x1fffe1, count: 21),
        (hex: 0x3fffe0, count: 22),
        (hex: 0x1fffe2, count: 21),
        (hex: 0x7fffed, count: 23),
        (hex: 0x3fffe1, count: 22),
        (hex: 0x7fffee, count: 23),
        (hex: 0x7fffef, count: 23),
        (hex: 0xfffea, count: 20),
        (hex: 0x3fffe2, count: 22),
        (hex: 0x3fffe3, count: 22),
        (hex: 0x3fffe4, count: 22),
        (hex: 0x7ffff0, count: 23),
        (hex: 0x3fffe5, count: 22),
        (hex: 0x3fffe6, count: 22),
        (hex: 0x7ffff1, count: 23),
        (hex: 0x3ffffe0, count: 26),
        (hex: 0x3ffffe1, count: 26),
        (hex: 0xfffeb, count: 20),
        (hex: 0x7fff1, count: 19),
        (hex: 0x3fffe7, count: 22),
        (hex: 0x7ffff2, count: 23),
        (hex: 0x3fffe8, count: 22),
        (hex: 0x1ffffec, count: 25),
        (hex: 0x3ffffe2, count: 26),
        (hex: 0x3ffffe3, count: 26),
        (hex: 0x3ffffe4, count: 26),
        (hex: 0x7ffffde, count: 27),
        (hex: 0x7ffffdf, count: 27),
        (hex: 0x3ffffe5, count: 26),
        (hex: 0xfffff1, count: 24),
        (hex: 0x1ffffed, count: 25),
        (hex: 0x7fff2, count: 19),
        (hex: 0x1fffe3, count: 21),
        (hex: 0x3ffffe6, count: 26),
        (hex: 0x7ffffe0, count: 27),
        (hex: 0x7ffffe1, count: 27),
        (hex: 0x3ffffe7, count: 26),
        (hex: 0x7ffffe2, count: 27),
        (hex: 0xfffff2, count: 24),
        (hex: 0x1fffe4, count: 21),
        (hex: 0x1fffe5, count: 21),
        (hex: 0x3ffffe8, count: 26),
        (hex: 0x3ffffe9, count: 26),
        (hex: 0xffffffd, count: 28),
        (hex: 0x7ffffe3, count: 27),
        (hex: 0x7ffffe4, count: 27),
        (hex: 0x7ffffe5, count: 27),
        (hex: 0xfffec, count: 20),
        (hex: 0xfffff3, count: 24),
        (hex: 0xfffed, count: 20),
        (hex: 0x1fffe6, count: 21),
        (hex: 0x3fffe9, count: 22),
        (hex: 0x1fffe7, count: 21),
        (hex: 0x1fffe8, count: 21),
        (hex: 0x7ffff3, count: 23),
        (hex: 0x3fffea, count: 22),
        (hex: 0x3fffeb, count: 22),
        (hex: 0x1ffffee, count: 25),
        (hex: 0x1ffffef, count: 25),
        (hex: 0xfffff4, count: 24),
        (hex: 0xfffff5, count: 24),
        (hex: 0x3ffffea, count: 26),
        (hex: 0x7ffff4, count: 23),
        (hex: 0x3ffffeb, count: 26),
        (hex: 0x7ffffe6, count: 27),
        (hex: 0x3ffffec, count: 26),
        (hex: 0x3ffffed, count: 26),
        (hex: 0x7ffffe7, count: 27),
        (hex: 0x7ffffe8, count: 27),
        (hex: 0x7ffffe9, count: 27),
        (hex: 0x7ffffea, count: 27),
        (hex: 0x7ffffeb, count: 27),
        (hex: 0xffffffe, count: 28),
        (hex: 0x7ffffec, count: 27),
        (hex: 0x7ffffed, count: 27),
        (hex: 0x7ffffee, count: 27),
        (hex: 0x7ffffef, count: 27),
        (hex: 0x7fffff0, count: 27),
        (hex: 0x3ffffee, count: 26),
        (hex: 0x3fffffff, count: 30)
    ]

    class func encode(value: String) -> [UInt8] {
        let writer = BitWriter()

        value.utf8.forEach {
            let entry = Huffman.data[Int($0)]
            //print("\(UnicodeScalar($0)) hex = \(entry.hex) - \(String(entry.hex, radix: 2)), length = \(entry.count)")
            writer.writeBits(entry.hex, length: entry.count)
        }

        writer.padToFullByte()

        return writer.bytes()
    }

    private class func leftPaddedBinary(value: Int, length: Int) -> String {
        let str = String(value, radix: 2)
        let pad = length - str.count
        if pad < 1 {
            return str
        } else {
            return "".padding(toLength: pad, withPad: "0", startingAt: 0) + str
        }
    }

    class func decode<Bytes : Sequence>(data bytes: Bytes) -> String where Bytes.Element == UInt8 {
        var foo: [String : Int] = [:]
        for (idx, header) in Huffman.data.enumerated() {
            foo[leftPaddedBinary(value: header.hex, length: header.count)] = idx
        }

        var ret: [Int] = []

        var value = ""
        for byte in bytes {
            for offset in (0 ..< 8).reversed() {
                let bit = String((byte >> offset) & 0b1)
                value += bit
                if let entry = foo[value] {
                    ret.append(entry)
                    value = ""
                }
            }
        }

        let i = ret.reduce("") { $0 + String(describing: UnicodeScalar($1)!) }
        print("decode returned \(i)")
        return i
    }
}

