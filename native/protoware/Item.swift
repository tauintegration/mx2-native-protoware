//
//  Item.swift
//  protoware
//
//  Created by PC on 5/8/26.
//

import Foundation
import SwiftUI

struct OpticsCheck: Identifiable {
    let id = UUID()
    let title: String
    var isComplete: Bool
}

struct ShotPreset {
    let name: String
    let subtitle: String
    let defaultFocusScore: Double
    let defaultExposureBias: Double
    let backgroundColor: Color
    let accentColor: Color

    static let samples = [
        ShotPreset(
            name: "Portrait",
            subtitle: "Face-forward setup",
            defaultFocusScore: 78,
            defaultExposureBias: 0,
            backgroundColor: Color(red: 0.08, green: 0.10, blue: 0.12),
            accentColor: .mint
        ),
        ShotPreset(
            name: "Product",
            subtitle: "Sharp detail setup",
            defaultFocusScore: 88,
            defaultExposureBias: 0.5,
            backgroundColor: Color(red: 0.10, green: 0.09, blue: 0.07),
            accentColor: .yellow
        ),
        ShotPreset(
            name: "Landscape",
            subtitle: "Wide scene setup",
            defaultFocusScore: 64,
            defaultExposureBias: -0.5,
            backgroundColor: Color(red: 0.06, green: 0.12, blue: 0.14),
            accentColor: .cyan
        )
    ]
}

struct SavedSetup: Identifiable {
    let id = UUID()
    let preset: String
    let readinessPercent: Int
    let note: String
}
