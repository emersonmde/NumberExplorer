//
//  Item.swift
//  NumberExplorer
//
//  Created by Matthew Emerson on 11/18/24.
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
