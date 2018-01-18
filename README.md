# SwiftHttp2
SwiftHttp2 is an implementation of the HTTP/2 specification written in Swift for macOS.  Requirements are derived from:

- [RFC7540](https://tools.ietf.org/html/rfc7540) - Hypertext Transfer Protocol Version 2 (HTTP/2)
- [RFC7541](https://tools.ietf.org/html/rfc7541) - HPACK: Header Compression for HTTP/2

The goal that started this project was the desire to build a tool to send Apple Push Notifications entirely from Swift. 

To connect to Apple's APNS you must pass a properly encoded Authorization header.  An example of how to do this can be found in the ApnsAuthHeader.swift file.  Please note this file is *not* compiled into the library.  It's just there as an example, and it requires that your project include the [OpenSSL-Universal](http://krzyzanowskim.github.io/OpenSSL) pod.

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1+ is required to build SwiftHttp2.

To integrate SwiftHttp2 into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.12'
use_frameworks!

target '<Your Target Name>' do
    pod 'SwiftHttp2'
end
```

Then, run the following command:

```bash
$ pod install
```

## Help Needed

The initial work to encode/decode headers and all the defined frame types is complete.  There are still multiple pieces needed though:

- Expand unit tests to cover all frame types.
- Add unit tests for the public interface (i.e. not using the @testable keyword)
    - Need to verify whether enough functionality is public.
- Write the Http2Session.swift file.
    - URLSession will close during idle periods so it can't be used for the client.




