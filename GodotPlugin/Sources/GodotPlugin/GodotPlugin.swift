import SwiftGodot
import SwiftUI
import UIKit
import FamilyControls
import ManagedSettings
import DeviceActivity

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
    // Define timer name
    private let focusActivity = DeviceActivityName("com.reel-it-in.focus")
    
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
            
            // Present app picker UI, and store user selection
            do {
                GD.print("Presenting FamilyActivityPicker...")
                
                let newSelection = try await self.showActivityPicker()
                self.selection = newSelection
                GD.print("Selection updated.")
                self.output_message.emit("Selection updated successfully.")
            } catch {
                let errorMsg = "Picker error: \(error.localizedDescription)"
                GD.print(errorMsg)
                self.output_message.emit(errorMsg)
            }
        }
    }

    @Callable
    func start_focus_block() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            if self.selection.applicationTokens.isEmpty {
                self.output_message.emit("Error: No apps selected.")
                return
            }

            // Setting schedule for 1 hour default (for now)
            let calendar = Calendar.current
            let now = Date()
            let end = now.addingTimeInterval(3600) // 1 hour

            let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
            let startComponents = calendar.dateComponents(components, from: now)
            let endComponents = calendar.dateComponents(components, from: end)
            let schedule = DeviceActivitySchedule(
                intervalStart: startComponents,
                intervalEnd: endComponents,
                repeats: false
            )

            // Start the timer
            let center = DeviceActivityCenter()
            do {
                try center.startMonitoring(self.focusActivity, during: schedule)
                
                // Turn on the shield
                self.store.shield.applications = self.selection.applicationTokens
                
                let successMsg = "Block started for 1 hour."
                GD.print(successMsg)
                self.output_message.emit(successMsg)
                
            } catch {
                let errorMsg = "Error starting block: \(error.localizedDescription)"
                GD.print(errorMsg)
                self.output_message.emit(errorMsg)
            }
        }
    }
    
    @Callable
    func stop_focus_block() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Turn off the shield
            self.store.shield.applications = nil
            
            // Stop the timer
            let center = DeviceActivityCenter()
            center.stopMonitoring([self.focusActivity])
            
            let msg = "Block stopped manually."
            GD.print(msg)
            self.output_message.emit(msg)
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