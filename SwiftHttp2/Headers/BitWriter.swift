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

// Inspired by https://github.com/raywenderlich/swift-algorithm-club/tree/master/Huffman%20Coding#the-code

internal final class BitWriter {
    private var data = Data()
    private var byte: UInt8 = 0
    private var count = 0
    private var totalBytes = 0

    func writeBits(_ lsbHex: Int, length: Int) {
        for i in (0 ..< length).reversed() {
            let bit = UInt8((lsbHex >> i) & 0x1)
            byte = (byte << 1) | bit

            count += 1

            guard count == 8 else { continue }

            data.append(&byte, count: 1)
            totalBytes += 1
            count = 0
            byte = 0
        }
    }

    func padToFullByte() {
        guard count > 0 else { return }

        if count < 8 {
            // If we don't have a full byte to encode then we pad the rest of
            // the bytes with 1's.  RFC7541 says to pad with the EOS string, which
            // is all 1's, not 0's
            let diff = UInt8(8 - count)

            byte = (byte << diff) | UInt8((1 << (8 - count)) - 1)
        }

        data.append(&byte, count: 1)
    }

    func bytes() -> [UInt8] {
        return [UInt8](data)
    }
}
