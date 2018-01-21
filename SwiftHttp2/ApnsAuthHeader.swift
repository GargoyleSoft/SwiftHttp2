// Copyright Â© 2018 Gargoyle Software, LLC
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

// pod 'OpenSSL-Universal'
// Then add ${SRCROOT}/SwiftSSL to the project's import paths.
import SwiftSSL

enum ApnsAuthHeaderError: Error {
    case keyPathNotReadable
    case sslInitFailure
    case sslDigestFailure
    case missingIdentifiers
}

final class ApnsAuthHeader {
    class func generateHeader(keyPath: String, authKeyId: String, teamId: String) throws -> String {
        guard !authKeyId.isEmpty, !teamId.isEmpty else {
            throw ApnsAuthHeaderError.missingIdentifiers
        }

        guard let fp = fopen(keyPath, "r") else {
            throw ApnsAuthHeaderError.keyPathNotReadable
        }

        var privateKey = EVP_PKEY_new()
        PEM_read_PrivateKey(fp, &privateKey, nil, nil)
        fclose(fp)

        let mdctx = EVP_MD_CTX_create()
        defer { EVP_MD_CTX_destroy(mdctx) }

        guard EVP_DigestSignInit(mdctx, nil, EVP_sha256(), nil, privateKey) == 1 else {
            throw ApnsAuthHeaderError.sslInitFailure
        }

        let headerObj: [String: Any] = ["alg" : "ES256", "kid" : authKeyId]
        let claimsObj: [String: Any] = ["iss" : teamId, "iat" : Date().timeIntervalSince1970]

        let header = try! JSONSerialization.data(withJSONObject: headerObj).base64EncodedString()
        let claims = try! JSONSerialization.data(withJSONObject: claimsObj).base64EncodedString()

        var slen = 0
        let message = "\(header).\(claims)"
        guard EVP_DigestUpdate(mdctx, message, message.count) == 1,
            EVP_DigestSignFinal(mdctx, nil, &slen) == 1
            else {
                throw ApnsAuthHeaderError.sslDigestFailure
        }

        var signature = UnsafeMutablePointer<UInt8>.allocate(capacity: slen)
        signature.initialize(to: 0, count: slen)

        defer {
            signature.deinitialize(count: slen)
            signature.deallocate(capacity: slen)
        }

        guard EVP_DigestSignFinal(mdctx, signature, &slen) == 1 else {
            throw ApnsAuthHeaderError.sslDigestFailure
        }

        var data = Data()
        data.append(signature, count: slen)

        let signed = data.base64EncodedString()

        return "\(header).\(claims).\(signed)"
    }
}


