//
//  Item.swift
//  Sharby
//
//  Created by Larry Brewer on 1/16/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
