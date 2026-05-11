//
//  ContentView.swift
//  wyckloptics
//
//  Created by PC on 5/8/26.
//

import SwiftUI
import DeclaredAgeRange

struct ContentView: View {
    @State private var focusScore = 72.0
    @State private var selectedPreset = 0
    @State private var exposureBias = 0.0
    @State private var showSetupDetails = false
    @State private var note = ""
    @State private var savedSetups: [SavedSetup] = []
    @State private var checks = [
        OpticsCheck(title: "Clean lens", isComplete: true),
        OpticsCheck(title: "Set focus", isComplete: false),
        OpticsCheck(title: "Check exposure", isComplete: false)
    ]

    private let presets = ShotPreset.samples
    private var selectedShotPreset: ShotPreset {
        presets[selectedPreset]
    }

    private var completedCheckCount: Int {
        checks.filter(\.isComplete).count
    }

    private var readiness: Double {
        let checklistScore = Double(completedCheckCount) / Double(checks.count)
        let focusScore = focusScore / 100
        let exposureScore = 1 - min(abs(exposureBias) / 2, 1)
        return (checklistScore * 0.45) + (focusScore * 0.4) + (exposureScore * 0.15)
    }

    private var readinessPercent: Int {
        Int((readiness * 100).rounded())
    }

    var body: some View {
        ZStack {
            selectedShotPreset.backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.25), value: selectedPreset)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wyckl Optics")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text(selectedShotPreset.subtitle)
                        .font(.title3)
                        .foregroundColor(selectedShotPreset.accentColor)
                }

                VStack(alignment: .leading, spacing: 16) {
                    ReadinessDial(percent: readinessPercent, accent: selectedShotPreset.accentColor)

                    Picker("Preset", selection: $selectedPreset) {
                        ForEach(presets.indices, id: \.self) { index in
                            Text(presets[index].name).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedPreset) { _ in
                        applyPresetDefaults()
                    }

                    HStack {
                        Text("Focus")
                        Spacer()
                        Text("\(Int(focusScore))%")
                            .fontWeight(.semibold)
                    }

                    Slider(value: $focusScore, in: 0...100, step: 1)
                        .tint(selectedShotPreset.accentColor)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Exposure")
                            Spacer()
                            Text(String(format: "%+.1f EV", exposureBias))
                                .fontWeight(.semibold)
                        }

                        Stepper("Adjust exposure", value: $exposureBias, in: -2...2, step: 0.5)
                            .labelsHidden()
                    }

                    VStack(spacing: 12) {
                        ForEach($checks) { $check in
                            Toggle(check.title, isOn: $check.isComplete)
                                .toggleStyle(SwitchToggleStyle(tint: selectedShotPreset.accentColor))
                        }
                    }

                    TextField("Add a quick note", text: $note)
                        .textFieldStyle(.roundedBorder)

                    HStack(spacing: 10) {
                        Button(action: saveCurrentSetup) {
                            Text("Save")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedShotPreset.accentColor)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }

                        Button(action: {
                            showSetupDetails = true
                        }) {
                            Text("Inspect")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }

                    Button("Reset Setup", action: resetSetup)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    AgeSignalSection()
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)

                    if !savedSetups.isEmpty {
                        SavedSetupsList(setups: savedSetups, accent: selectedShotPreset.accentColor)
                    }
                }
                .padding(24)
            }
        }
        .sheet(isPresented: $showSetupDetails) {
            SetupDetailsSheet(
                preset: selectedShotPreset,
                readinessPercent: readinessPercent,
                focusScore: Int(focusScore),
                exposureBias: exposureBias,
                completedChecks: completedCheckCount,
                totalChecks: checks.count,
                note: note
            )
        }
    }

    private func resetSetup() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedPreset = 0
            applyPresetDefaults()
            checks = checks.map { OpticsCheck(title: $0.title, isComplete: false) }
            note = ""
        }
    }

    private func applyPresetDefaults() {
        withAnimation(.easeInOut(duration: 0.2)) {
            focusScore = selectedShotPreset.defaultFocusScore
            exposureBias = selectedShotPreset.defaultExposureBias
        }
    }

    private func saveCurrentSetup() {
        let setup = SavedSetup(
            preset: selectedShotPreset.name,
            readinessPercent: readinessPercent,
            note: note.isEmpty ? "No note" : note
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            savedSetups.insert(setup, at: 0)
            note = ""
        }
    }
}

private struct ReadinessDial: View {
    let percent: Int
    let accent: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: CGFloat(percent) / 100)
                    .stroke(accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: percent)

                Text("\(percent)%")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(width: 82, height: 82)

            VStack(alignment: .leading, spacing: 6) {
                Text("Readiness")
                    .font(.headline)

                Text(readinessText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var readinessText: String {
        if percent >= 85 {
            return "Ready to shoot"
        } else if percent >= 60 {
            return "Close, tune the setup"
        } else {
            return "Needs attention"
        }
    }
}

private struct SavedSetupsList: View {
    let setups: [SavedSetup]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved setups")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(setups.prefix(4)) { setup in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(setup.preset)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(setup.note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(setup.readinessPercent)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accent.opacity(0.18))
                        .foregroundColor(accent)
                        .cornerRadius(8)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
}

private struct SetupDetailsSheet: View {
    let preset: ShotPreset
    let readinessPercent: Int
    let focusScore: Int
    let exposureBias: Double
    let completedChecks: Int
    let totalChecks: Int
    let note: String

    var body: some View {
        NavigationView {
            List {
                Section("Setup") {
                    DetailRow(label: "Preset", value: preset.name)
                    DetailRow(label: "Readiness", value: "\(readinessPercent)%")
                    DetailRow(label: "Focus", value: "\(focusScore)%")
                    DetailRow(label: "Exposure", value: String(format: "%+.1f EV", exposureBias))
                    DetailRow(label: "Checklist", value: "\(completedChecks) of \(totalChecks)")
                }

                Section("Note") {
                    Text(note.isEmpty ? "No note yet" : note)
                }
            }
            .navigationTitle("Shot Details")
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

private enum AgeSignalMode: String, CaseIterable, Identifiable {
    case localSandbox
    case appleAPI

    var id: String { rawValue }

    var title: String {
        switch self {
        case .localSandbox:
            return "Sandbox"
        case .appleAPI:
            return "Apple"
        }
    }
}

private struct AgeSignalScenario: Identifiable {
    let id: String
    let name: String
    let ageResult: AgeSignalResult
    let regulatoryResult: RegulatorySignalResult

    static let samples = [
        AgeSignalScenario(
            id: "under13",
            name: "Under 13",
            ageResult: .sharing(
                lowerBound: nil,
                upperBound: 12,
                source: "Guardian verified",
                parentalControls: "Active"
            ),
            regulatoryResult: RegulatorySignalResult(
                title: "Child",
                detail: "Sandbox case: age assurance applies and parent consent controls sensitive features.",
                ageFeaturesRequired: true,
                ageRangeRequired: true,
                parentConsentRequired: true,
                adultNotificationRequired: false,
                tone: .red
            )
        ),
        AgeSignalScenario(
            id: "13to15",
            name: "13-15",
            ageResult: .sharing(
                lowerBound: 13,
                upperBound: 15,
                source: "Self declared",
                parentalControls: "Possible"
            ),
            regulatoryResult: RegulatorySignalResult(
                title: "Young teen",
                detail: "Sandbox case: age features apply, with tighter defaults and possible guardian controls.",
                ageFeaturesRequired: true,
                ageRangeRequired: true,
                parentConsentRequired: true,
                adultNotificationRequired: false,
                tone: .orange
            )
        ),
        AgeSignalScenario(
            id: "16to17",
            name: "16-17",
            ageResult: .sharing(
                lowerBound: 16,
                upperBound: 17,
                source: "Self declared",
                parentalControls: "Possible"
            ),
            regulatoryResult: RegulatorySignalResult(
                title: "Older teen",
                detail: "Sandbox case: age range is known, but some significant changes may still need notice.",
                ageFeaturesRequired: true,
                ageRangeRequired: true,
                parentConsentRequired: false,
                adultNotificationRequired: true,
                tone: .orange
            )
        ),
        AgeSignalScenario(
            id: "18plus",
            name: "18+",
            ageResult: .sharing(
                lowerBound: 18,
                upperBound: nil,
                source: "Payment verified",
                parentalControls: "None"
            ),
            regulatoryResult: RegulatorySignalResult(
                title: "Adult",
                detail: "Sandbox case: full experience can be enabled, while still respecting regional rules.",
                ageFeaturesRequired: true,
                ageRangeRequired: true,
                parentConsentRequired: false,
                adultNotificationRequired: false,
                tone: .green
            )
        ),
        AgeSignalScenario(
            id: "declined",
            name: "Declined",
            ageResult: .declined,
            regulatoryResult: .declined
        ),
        AgeSignalScenario(
            id: "notRequired",
            name: "Not required",
            ageResult: .sharing(
                lowerBound: nil,
                upperBound: nil,
                source: "Not requested",
                parentalControls: "Unknown"
            ),
            regulatoryResult: RegulatorySignalResult(
                title: "Not required",
                detail: "Sandbox case: age assurance is not required for this user or region.",
                ageFeaturesRequired: false,
                ageRangeRequired: false,
                parentConsentRequired: false,
                adultNotificationRequired: false,
                tone: .gray
            )
        )
    ]
}

private struct RegulatorySignalResult {
    let title: String
    let detail: String
    let ageFeaturesRequired: Bool
    let ageRangeRequired: Bool
    let parentConsentRequired: Bool
    let adultNotificationRequired: Bool
    let tone: Color

    static let localSandbox = RegulatorySignalResult(
        title: "Sandbox",
        detail: "Choose a fake scenario to see how the UI responds before using Apple sandbox testing.",
        ageFeaturesRequired: false,
        ageRangeRequired: false,
        parentConsentRequired: false,
        adultNotificationRequired: false,
        tone: .gray
    )

    static let appleModeIdle = RegulatorySignalResult(
        title: "Apple mode",
        detail: "Use the real API request to update this panel from the system response.",
        ageFeaturesRequired: false,
        ageRangeRequired: false,
        parentConsentRequired: false,
        adultNotificationRequired: false,
        tone: .gray
    )

    static let appleModeRequesting = RegulatorySignalResult(
        title: "Requesting",
        detail: "Waiting for the system age range sheet.",
        ageFeaturesRequired: true,
        ageRangeRequired: true,
        parentConsentRequired: false,
        adultNotificationRequired: false,
        tone: .orange
    )

    static let declined = RegulatorySignalResult(
        title: "Restricted",
        detail: "No age range was shared, so the app should choose a conservative experience.",
        ageFeaturesRequired: true,
        ageRangeRequired: true,
        parentConsentRequired: false,
        adultNotificationRequired: false,
        tone: .red
    )

    static let unknown = RegulatorySignalResult(
        title: "Unknown",
        detail: "The response was not recognized. Keep the conservative experience.",
        ageFeaturesRequired: true,
        ageRangeRequired: true,
        parentConsentRequired: false,
        adultNotificationRequired: false,
        tone: .orange
    )

    static let unavailable = RegulatorySignalResult(
        title: "Unavailable",
        detail: "The system service was unavailable or the request failed.",
        ageFeaturesRequired: false,
        ageRangeRequired: false,
        parentConsentRequired: false,
        adultNotificationRequired: false,
        tone: .red
    )

    static func fromAgeResult(_ result: AgeSignalResult, sandbox: Bool) -> RegulatorySignalResult {
        let title = sandbox ? "Sandbox" : "Apple API"

        if let upperBound = result.upperBound, upperBound < 13 {
            return RegulatorySignalResult(
                title: title,
                detail: "Age range indicates a child experience.",
                ageFeaturesRequired: true,
                ageRangeRequired: true,
                parentConsentRequired: true,
                adultNotificationRequired: false,
                tone: .red
            )
        }

        if let lowerBound = result.lowerBound, lowerBound >= 18 {
            return RegulatorySignalResult(
                title: title,
                detail: "Age range indicates an adult experience.",
                ageFeaturesRequired: true,
                ageRangeRequired: true,
                parentConsentRequired: false,
                adultNotificationRequired: false,
                tone: .green
            )
        }

        return RegulatorySignalResult(
            title: title,
            detail: "Age range indicates a teen experience with conservative defaults.",
            ageFeaturesRequired: true,
            ageRangeRequired: true,
            parentConsentRequired: true,
            adultNotificationRequired: false,
            tone: .orange
        )
    }
}

private struct AgeSignalSection: View {
    @State private var mode: AgeSignalMode = .localSandbox
    @State private var selectedScenarioID = AgeSignalScenario.samples[0].id
    @State private var result = AgeSignalResult.notRequested
    @State private var regulatory = RegulatorySignalResult.localSandbox

    private var selectedScenario: AgeSignalScenario {
        AgeSignalScenario.samples.first { $0.id == selectedScenarioID } ?? AgeSignalScenario.samples[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Signal mode", selection: $mode) {
                ForEach(AgeSignalMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _ in
                applyLocalScenario()
            }

            if mode == .localSandbox {
                Picker("Sandbox scenario", selection: $selectedScenarioID) {
                    ForEach(AgeSignalScenario.samples) { scenario in
                        Text(scenario.name).tag(scenario.id)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedScenarioID) { _ in
                    applyLocalScenario()
                }
            }

            AgeSignalPanel(
                title: result.title,
                detail: result.detail,
                lowerBound: result.lowerBound,
                upperBound: result.upperBound,
                decision: result.decision,
                tone: result.tone,
                source: result.source,
                parentalControls: result.parentalControls
            )

            RegulatorySignalPanel(result: regulatory)

            if mode == .appleAPI {
                if #available(iOS 26.0, *) {
                    DeclaredAgeRangeRequestButton { ageResult, regulatoryResult in
                        result = ageResult
                        regulatory = regulatoryResult
                    }
                } else {
                    Text("Apple API mode requires iOS 26 or later. Use Local Sandbox on this device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear(perform: applyLocalScenario)
    }

    private func applyLocalScenario() {
        guard mode == .localSandbox else {
            result = .notRequested
            regulatory = .appleModeIdle
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            result = selectedScenario.ageResult
            regulatory = selectedScenario.regulatoryResult
        }
    }
}

@available(iOS 26.0, *)
private struct DeclaredAgeRangeRequestButton: View {
    @Environment(\.requestAgeRange) private var requestAgeRange
    let update: (AgeSignalResult, RegulatorySignalResult) -> Void

    var body: some View {
        Button(action: {
            Task {
                await requestDeclaredAgeRange()
            }
        }) {
            Text("Request Age Range")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    private func requestDeclaredAgeRange() async {
        update(.requesting, .appleModeRequesting)

        do {
            let response = try await requestAgeRange(ageGates: 13, 16, 18)

            switch response {
            case let .sharing(ageRange):
                let ageResult = AgeSignalResult.sharing(
                    lowerBound: ageRange.lowerBound,
                    upperBound: ageRange.upperBound,
                    source: "Apple Declared Age Range"
                )
                update(ageResult, .fromAgeResult(ageResult, sandbox: false))

            case .declinedSharing:
                update(.declined, .declined)

            @unknown default:
                update(.unknownResponse, .unknown)
            }
        } catch {
            update(.failed(error.localizedDescription), .unavailable)
        }
    }
}

private struct AgeSignalPanel: View {
    let title: String
    let detail: String
    let lowerBound: Int?
    let upperBound: Int?
    let decision: String
    let tone: Color
    let source: String
    let parentalControls: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Age signal")
                    .font(.headline)

                Spacer()

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(tone.opacity(0.15))
                    .foregroundColor(tone)
                    .cornerRadius(8)
            }

            Text(detail)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                AgeSignalMetric(label: "Lower", value: boundText(lowerBound, fallback: "below gate"))
                AgeSignalMetric(label: "Upper", value: boundText(upperBound, fallback: "open ended"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Decision")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(decision)
                    .font(.body)
                    .fontWeight(.medium)
            }

            HStack(spacing: 12) {
                AgeSignalMetric(label: "Source", value: source)
                AgeSignalMetric(label: "Controls", value: parentalControls)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func boundText(_ bound: Int?, fallback: String) -> String {
        bound.map(String.init) ?? fallback
    }
}

private struct RegulatorySignalPanel: View {
    let result: RegulatorySignalResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Regulatory signal")
                    .font(.headline)

                Spacer()

                Text(result.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(result.tone.opacity(0.15))
                    .foregroundColor(result.tone)
                    .cornerRadius(8)
            }

            Text(result.detail)
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                RegulatoryRow(label: "Age features required", value: result.ageFeaturesRequired ? "Yes" : "No")
                RegulatoryRow(label: "Age range required", value: result.ageRangeRequired ? "Yes" : "No")
                RegulatoryRow(label: "Parent consent needed", value: result.parentConsentRequired ? "Yes" : "No")
                RegulatoryRow(label: "Adult notification", value: result.adultNotificationRequired ? "Yes" : "No")
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct RegulatoryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

private struct AgeSignalMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
    }
}

private struct AgeSignalResult {
    let title: String
    let detail: String
    let lowerBound: Int?
    let upperBound: Int?
    let decision: String
    let tone: Color
    let source: String
    let parentalControls: String

    static let notRequested = AgeSignalResult(
        title: "Idle",
        detail: "Tap the request button to ask the system for the declared age range.",
        lowerBound: nil,
        upperBound: nil,
        decision: "No age-gated decision yet",
        tone: .gray,
        source: "None",
        parentalControls: "Unknown"
    )

    static let requesting = AgeSignalResult(
        title: "Requesting",
        detail: "Waiting for the system age range sheet.",
        lowerBound: nil,
        upperBound: nil,
        decision: "Pending user response",
        tone: .orange,
        source: "Apple API",
        parentalControls: "Unknown"
    )

    static func sharing(
        lowerBound: Int?,
        upperBound: Int?,
        source: String = "Local sandbox",
        parentalControls: String = "None"
    ) -> AgeSignalResult {
        AgeSignalResult(
            title: "Shared",
            detail: "The system returned a privacy-preserving age range.",
            lowerBound: lowerBound,
            upperBound: upperBound,
            decision: decisionText(lowerBound: lowerBound, upperBound: upperBound),
            tone: .green,
            source: source,
            parentalControls: parentalControls
        )
    }

    static let declined = AgeSignalResult(
        title: "Declined",
        detail: "The user declined to share an age range.",
        lowerBound: nil,
        upperBound: nil,
        decision: "Use the restricted or default experience",
        tone: .red,
        source: "Apple API",
        parentalControls: "Unknown"
    )

    static let unknownResponse = AgeSignalResult(
        title: "Unknown",
        detail: "The framework returned a response this app does not recognize yet.",
        lowerBound: nil,
        upperBound: nil,
        decision: "Use the restricted or default experience",
        tone: .orange,
        source: "Unknown",
        parentalControls: "Unknown"
    )

    static func failed(_ message: String) -> AgeSignalResult {
        AgeSignalResult(
            title: "Error",
            detail: message,
            lowerBound: nil,
            upperBound: nil,
            decision: "Use the restricted or default experience",
            tone: .red,
            source: "Unavailable",
            parentalControls: "Unknown"
        )
    }

    private static func decisionText(lowerBound: Int?, upperBound: Int?) -> String {
        if let upperBound, upperBound < 13 {
            return "Child experience"
        }

        guard let lowerBound else {
            return "Child experience"
        }

        if lowerBound >= 18 {
            return "Adult experience"
        } else if lowerBound >= 16 {
            return "Older teen experience"
        } else if lowerBound >= 13 {
            return "Teen experience"
        } else {
            return "Child experience"
        }
    }
}
