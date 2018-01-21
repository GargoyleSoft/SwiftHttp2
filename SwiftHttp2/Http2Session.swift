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

enum Http2SessionError : Error {
    case readStreamCreateFailed
    case writeStreamCreateFailed
    case outputStreamNotOpen
}

// https://developer.apple.com/library/content/technotes/tn2232/_index.html

// https://github.com/nathanborror/swift-http2/blob/master/Sources/Http2.swift
final public class Http2Session : NSObject {
    private static let connectionPreface = "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n".toUInt8Array()

    private let host: String
    private let port: Int
    private let writeQueue: OperationQueue

    private let runLoop = RunLoop()

    private var unprocessedBytes: [UInt8] = []

    internal var inputStream: InputStream?
    internal var outputStream: OutputStream?

    private init(host: String, port: Int = 443, streamProperties: [Stream.PropertyKey : Any?] = [:]) throws {
        self.host = host
        self.port = port

        writeQueue = OperationQueue()
        writeQueue.qualityOfService = .userInitiated
        writeQueue.isSuspended = true

        Stream.getStreamsToHost(withName: host, port: port, inputStream: &inputStream, outputStream: &outputStream)

        super.init()

        // Make sure security level is set.  If they sent a value, use theirs instead of ours.
        let properties = streamProperties.merging([.socketSecurityLevelKey : StreamSocketSecurityLevel.negotiatedSSL]) {
            current, _ in
            current
        }

        inputStream!.delegate = self
        properties.forEach {
            inputStream!.setProperty($0.value, forKey: $0.key)
        }
        inputStream!.schedule(in: .main, forMode: .defaultRunLoopMode)
        inputStream!.open()

        outputStream!.delegate = self
        properties.forEach {
            outputStream!.setProperty($0.value, forKey: $0.key)
        }
        outputStream!.schedule(in: .main, forMode: .defaultRunLoopMode)
        outputStream!.open()
    }

    public class func createClient(host: String, port: Int = 443) throws -> Http2Session {
        Http2StreamCache.shared.initialize(as: .client)
        return try Http2Session(host: host, port: port)
    }

    public class func createServer() throws -> Http2Session {
        Http2StreamCache.shared.initialize(as: .server)
        return try Http2Session(host: "", port: 0)
    }

    public func disconnect(sendGoAwayFrame: Bool = true) {
        writeQueue.cancelAllOperations()

        if let inputStream = inputStream {
            inputStream.close()
            inputStream.delegate = nil
            self.inputStream = nil
        }

        if sendGoAwayFrame, let lastStream = Http2StreamCache.shared.orderedStreams().last {
            let goAway = GoAwayFrame(lastStream: lastStream, errorCode: .none)
            _ = try? write(goAway)
            writeQueue.waitUntilAllOperationsAreFinished()
        }

        if let outputStream = outputStream {
            outputStream.close()
            outputStream.delegate = nil
            self.outputStream = nil
        }
    }

    internal func closeStreams() {

    }

    public func write(_ frame: AbstractFrame) throws {
        guard let outputStream = outputStream else {
            throw Http2SessionError.outputStreamNotOpen
        }

        let encoded = try frame.encode()

        writeQueue.addOperation {
            outputStream.write(encoded, maxLength: encoded.count)
        }
    }

    private func read() {
        guard let inputStream = inputStream else { return }

        let length = 4096
        var buffer = [UInt8](repeating: 0, count: length)
        let bytesRead = inputStream.read(&buffer, maxLength: length)

        if bytesRead > 0 {
            unprocessedBytes += buffer[0 ..< bytesRead]

            let frame = try! AbstractFrame.decode(data: unprocessedBytes)
            print(frame)
        } else if bytesRead == 0 {
            disconnect(sendGoAwayFrame: false)
        } else if let error = inputStream.streamError {
            disconnect(sendGoAwayFrame: false)
            print(error)
        }
    }
}

extension Http2Session :  StreamDelegate {
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        // According to Quinn, we'll never get more than one event at a time.
        // https://forums.developer.apple.com/thread/95632
        if eventCode.isSubset(of: [.endEncountered, .errorOccurred]) {
            disconnect(sendGoAwayFrame: false)
        } else if eventCode.contains(.hasBytesAvailable) {
            guard aStream == inputStream else { return }
            read()
        } else if eventCode.contains(.openCompleted) {
            guard aStream == outputStream else { return }
            outputStream!.write(Http2Session.connectionPreface, maxLength: Http2Session.connectionPreface.count)

            writeQueue.isSuspended = false
        }
    }
}
