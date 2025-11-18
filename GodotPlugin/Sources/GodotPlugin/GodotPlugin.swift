import SwiftGodot
import SwiftUI
import UIKit
import FamilyControls
import ManagedSettings

final class SendableWrapper<T>: @unchecked Sendable {
    let value: T
    @MainActor
    init(_ value: T) { self.value = value }
}

#initSwiftExtension(
    cdecl: "swift_entry_point",
    types: [GodotPlugin.self]
)

@Godot
class GodotPlugin: RefCounted, @unchecked Sendable {
    
    // Define a signal that sends a String
    @Signal var output_message: SignalWithArguments<String>

    // Will hold app selection state
    private var selection = FamilyActivitySelection()
    private let store = ManagedSettingsStore()
    
    // Callable: Godot → Swift
    @Callable
    func send_message_to_swift(message: String) -> String {
        print("Received message in Swift: \(message)")
        return "Swift processed: \(message)"
    }
    
    // Callable: Godot calls this → Swift emits signal → Godot receives
    @Callable
    func trigger_swift_signal() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            print("Godot called triggerSwiftSignal, emitting outputMessage signal...")
            self.output_message.emit("This string came from a swift file!")
        }
    }
    
    // Request screen time authorization from user
    @Callable
    func request_authorization() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            let center = AuthorizationCenter.shared
            do {
                try await center.requestAuthorization(for: .individual)
                let status = center.authorizationStatus
                switch status {
                case .notDetermined:
                    GD.print("Auth status: not determined")
                    self.output_message.emit("Auth status: not determined")
                case .denied:
                    GD.print("Auth status: denied")
                    self.output_message.emit("Auth status: denied")
                case .approved:
                    GD.print("Auth status: approved")
                    self.output_message.emit("Auth status: approved")
                @unknown default:
                    GD.print("Auth status: unknown")
                    self.output_message.emit("Auth status: unknown")
                }
            } catch {
                let errorMsg = "Auth error: \(error.localizedDescription)"
                GD.print(errorMsg)
                self.output_message.emit(errorMsg)
            }
        }
    }

    @Callable
    func present_app_picker() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let center = AuthorizationCenter.shared

            // Ensure family controls request is approved prior to showing app picker
            guard center.authorizationStatus == .approved else {
                let errorMsg = "Error: Not authorized. Please authorize first."
                GD.print(errorMsg)
                self.output_message.emit(errorMsg)
                return
            }
            
            do {
                GD.print("Presenting FamilyActivityPicker...")
                
                let newSelection = try await self.showActivityPicker()
                self.selection = newSelection
                GD.print("Selection updated.")
                self.output_message.emit("Selection updated successfully.")

                // Apply selection to ManagedSettingsStore (telling it what to block)
                self.store.shield.applications = self.selection.applicationTokens.isEmpty ? nil : self.selection.applicationTokens
                GD.print("ManagedSettingsStore updated with new app tokens.")
                
            } catch {
                let errorMsg = "Picker error: \(error.localizedDescription)"
                GD.print(errorMsg)
                self.output_message.emit(errorMsg)
            }
        }
    }

    @MainActor
    private func showActivityPicker() async throws -> FamilyActivitySelection {
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: { $0.isKeyWindow })?
            .rootViewController
        else {
            throw PickerError.cannotFindRootViewController
        }
        
        // Await the wrapper, then return its value
        let wrapper: SendableWrapper<FamilyActivitySelection> = try await withCheckedThrowingContinuation { continuation in
            let pickerView = PickerView(continuation: continuation)
            let hostingController = UIHostingController(rootView: pickerView)
            rootViewController.present(hostingController, animated: true)
        }
        return wrapper.value
    }

    @MainActor
    struct PickerView: View {
        @State private var selection = FamilyActivitySelection()
        
        var continuation: CheckedContinuation<SendableWrapper<FamilyActivitySelection>, Error>     

        @SwiftUI.Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
        
        var body: some View {
            VStack {
                FamilyActivityPicker(selection: $selection)
                
                Button("Done") {
                    continuation.resume(returning: SendableWrapper(self.selection))                    
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            }
        }
    }

    enum PickerError: Error, LocalizedError {
        case cannotFindRootViewController
        var errorDescription: String? {
            "Failed to find the app's root view controller to present the picker."
        }
    }
}