// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftGodot

#initSwiftExtension(
    cdecl: "swift_entry_point",
    types: [GodotPlugin.self]
)

@Godot
class GodotPlugin: RefCounted {

    // Define a signal that sends a String
    @Signal var output_message: SignalWithArguments<String>

    // Callable: Godot → Swift
    @Callable
    func send_message_to_swift(message: String) -> String {
        print("Received message in Swift: \(message)")
        return "Swift processed: \(message)"
    }

    // Callable: Godot calls this → Swift emits signal → Godot receives
    @Callable
    func trigger_swift_signal() {
        print("Godot called triggerSwiftSignal, emitting outputMessage signal...")
        output_message.emit("This string came from a swift file!")
    }

    // Request screen time authorization from user
    @Callable
    func request_authorization() {
        Task { @MainActor in
        let center = AuthorizationCenter.shared
        do {
            try await center.requestAuthorization(for: .individual)
            let status = center.authorizationStatus
            switch status {
                case .notDetermined:
                    GD.print("Auth status: not determined")
                case .denied:
                    GD.print("Auth status: denied")
                case .approved:
                    GD.print("Auth status: approved")
                @unknown default:
                    GD.print("Auth status: unknown")
            }
        } catch {
            GD.print("Failed to request FamilyControls authentication: \(error.localizedDescription)")
        }
    }
}

// @Signal var applicationTokensSelected: SignalWithArguments<(PackedByteArray)>
// @Signal var authorizationStatusChanged: SignalWithArguments<(Int)>
// @Signal var restrictionsUpdated: SignalWithArguments<(Bool)>
// private let store = ManagedSettingsStore()