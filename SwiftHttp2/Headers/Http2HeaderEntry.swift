//
//  HeaderEntry.swift
//  SwiftHttp2
//
//  Created by Scott Grosch on 1/20/18.
//  Copyright © 2018 Gargoyle Software, LLC. All rights reserved.
//

import Foundation

public struct Http2HeaderEntry {
    var field: String
    var value: String
    var indexing: Http2HeaderFieldIndexType?

    public init(field: String, value: String = "", indexing: Http2HeaderFieldIndexType? = nil) {
        self.field = field
        self.value = value
        self.indexing = indexing
    }
}
