//
//  Item.swift
//  SignBridge_1
//
//  Created by KIET2 on 23/10/26.
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
