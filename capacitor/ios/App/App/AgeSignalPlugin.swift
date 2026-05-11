import Foundation
import Capacitor
import UIKit

#if canImport(DeclaredAgeRange)
import DeclaredAgeRange
#endif

@objc(AgeSignalPlugin)
public class AgeSignalPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "AgeSignalPlugin"
    public let jsName = "AgeSignal"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestDeclaredAge", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "checkAvailability", returnType: CAPPluginReturnPromise)
    ]

    @objc func checkAvailability(_ call: CAPPluginCall) {
        #if canImport(DeclaredAgeRange)
        if #available(iOS 26.0, *) {
            call.resolve([
                "available": true,
                "source": "apple",
                "status": "notAvailable",
                "message": "Declared Age Range is available on this SDK and OS."
            ])
        } else {
            call.resolve(unavailablePayload("Declared Age Range requires iOS 26 or newer."))
        }
        #else
        call.resolve(unavailablePayload("DeclaredAgeRange framework is not present in this SDK."))
        #endif
    }

    @objc func requestDeclaredAge(_ call: CAPPluginCall) {
        #if canImport(DeclaredAgeRange)
        if #available(iOS 26.0, *) {
            Task { @MainActor in
                guard let viewController = self.bridge?.viewController else {
                    call.resolve(self.unavailablePayload("No view controller is available to present the age range sheet."))
                    return
                }

                let gates = self.normalizedAgeGates(call.getArray("ageGates", Int.self) ?? [13, 16, 18])

                do {
                    let response = try await AgeRangeService.shared.requestAgeRange(
                        ageGates: gates[0],
                        gates.count > 1 ? gates[1] : nil,
                        gates.count > 2 ? gates[2] : nil,
                        in: viewController
                    )

                    switch response {
                    case .declinedSharing:
                        call.resolve([
                            "available": true,
                            "source": "apple",
                            "status": "declined",
                            "message": "The person declined to share their age range."
                        ])
                    case .sharing(let ageRange):
                        var payload: [String: Any] = [
                            "available": true,
                            "source": "apple",
                            "status": "shared",
                            "activeParentalControls": self.parentalControlNames(ageRange.activeParentalControls),
                            "message": "The person shared an age range."
                        ]

                        if let lowerBound = ageRange.lowerBound {
                            payload["lowerBound"] = lowerBound
                        }

                        if let upperBound = ageRange.upperBound {
                            payload["upperBound"] = upperBound
                        }

                        if let declaration = ageRange.ageRangeDeclaration {
                            payload["ageRangeDeclaration"] = self.declarationName(declaration)
                        }

                        call.resolve(payload)
                    }
                } catch {
                    call.resolve(self.unavailablePayload("Declared Age Range request failed: \(error.localizedDescription)"))
                }
            }
        } else {
            call.resolve(unavailablePayload("Declared Age Range requires iOS 26 or newer."))
        }
        #else
        call.resolve(unavailablePayload("DeclaredAgeRange framework is not present in this SDK."))
        #endif
    }

    private func normalizedAgeGates(_ input: [Int]) -> [Int] {
        let gates = Array(Set(input.filter { $0 > 0 })).sorted().prefix(3)
        return gates.isEmpty ? [13, 16, 18] : Array(gates)
    }

    private func unavailablePayload(_ message: String) -> [String: Any] {
        [
            "available": false,
            "source": "apple",
            "status": "notAvailable",
            "message": message
        ]
    }

    #if canImport(DeclaredAgeRange)
    @available(iOS 26.0, *)
    private func parentalControlNames(_ controls: AgeRangeService.ParentalControls) -> [String] {
        controls.contains(.communicationLimits) ? ["communicationLimits"] : []
    }

    @available(iOS 26.0, *)
    private func declarationName(_ declaration: AgeRangeService.AgeRangeDeclaration) -> String {
        switch declaration {
        case .selfDeclared:
            return "selfDeclared"
        case .guardianDeclared:
            return "guardianDeclared"
        }
    }
    #endif
}
