//
//  Item.swift
//  Version1.0
//
//  Created by 李靓 on 10/29/25.
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
