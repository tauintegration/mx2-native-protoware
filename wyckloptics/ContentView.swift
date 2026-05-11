//
//  ContentView.swift
//  wyckloptics
//
//  Created by PC on 5/8/26.
//

import SwiftUI

struct ContentView: View {
    @State private var focusScore = 72.0
    @State private var selectedPreset = 0
    @State private var checks = [
        OpticsCheck(title: "Clean lens", isComplete: true),
        OpticsCheck(title: "Set focus", isComplete: false),
        OpticsCheck(title: "Check exposure", isComplete: false)
    ]

    private let presets = ["Portrait", "Product", "Landscape"]

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.10, blue: 0.12)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wyckl Optics")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text("Shot setup")
                        .font(.title3)
                        .foregroundColor(.mint)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Picker("Preset", selection: $selectedPreset) {
                        ForEach(presets.indices, id: \.self) { index in
                            Text(presets[index]).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Focus")
                        Spacer()
                        Text("\(Int(focusScore))%")
                            .fontWeight(.semibold)
                    }

                    Slider(value: $focusScore, in: 0...100, step: 1)

                    VStack(spacing: 12) {
                        ForEach($checks) { $check in
                            Toggle(check.title, isOn: $check.isComplete)
                                .toggleStyle(SwitchToggleStyle(tint: .mint))
                        }
                    }

                    Button(action: resetSetup) {
                        Text("Reset Setup")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.mint)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)

                Spacer()
            }
            .padding(24)
        }
    }

    private func resetSetup() {
        focusScore = 72
        selectedPreset = 0
        checks = checks.map { OpticsCheck(title: $0.title, isComplete: false) }
    }
}
