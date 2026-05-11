//
//  Item.swift
//  wyckloptics
//
//  Created by PC on 5/8/26.
//

import Foundation

struct OpticsCheck: Identifiable {
    let id = UUID()
    let title: String
    var isComplete: Bool
}
