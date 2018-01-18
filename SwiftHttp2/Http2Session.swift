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

final public class Http2Session : NSObject {
    private static let connectionPreface = "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"
    
    private let host: String
    private let port: Int

    private var session: URLSession!
    private var streamTask: URLSessionStreamTask!

    private init(host: String, port: Int = 443) {
        self.host = host
        self.port = port

        super.init()

        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    public class func createClient(host: String, port: Int = 443) -> Http2Session {
        Http2StreamCache.shared.initialize(as: .client)
        return Http2Session(host: host, port: port)
    }

    public class func createServer() -> Http2Session {
        Http2StreamCache.shared.initialize(as: .server)
        return Http2Session(host: "", port: 0)
    }


    public func connect() {
        streamTask = session.streamTask(withHostName: host, port: port)
        streamTask.resume()
        streamTask.captureStreams()
        streamTask.startSecureConnection()
    }

    public func disconnect() {
        if let _ = Http2StreamCache.shared.orderedStreams().last {
            //let goAway = GoAwayFrame(lastStream: lastStream, errorCode: .none)
        }

        streamTask.stopSecureConnection()
    }
}

extension Http2Session : URLSessionDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("Got asked for credential")
        completionHandler(.useCredential, nil)
    }

    
}

extension Http2Session: URLSessionStreamDelegate {
    public func urlSession(_ session: URLSession, streamTask: URLSessionStreamTask, didBecome inputStream: InputStream, outputStream: OutputStream) {
        print("Called didBecome:inputStream:outputStream:")
    }
}
