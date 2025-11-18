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
                let statusMessage: String
                switch status {
                case .notDetermined:
                    statusMessage = "Auth status: not determined"
                case .denied:
                    statusMessage = "Auth status: denied"
                case .approved:
                    statusMessage = "Auth status: approved"
                @unknown default:
                    statusMessage = "Auth status: unknown"
                }
                GD.print(statusMessage)
                self.output_message.emit(statusMessage)
            } catch {
                GD.print("Auth error: \(error.localizedDescription)")
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
                GD.print("Error: Not authorized. Please authorize first.")
                return
            }
            
            // Present app picker UI, and store user selection
            do {
                GD.print("Presenting FamilyActivityPicker...")
                
                let newSelection = try await self.showActivityPicker()
                self.selection = newSelection

                let successMessage = "Selection updated successfully."
                GD.print(successMessage)
                self.output_message.emit(successMessage)
            } catch {
                let errorMessage = "Error: \(error.localizedDescription)"
                GD.print(errorMessage)
                self.output_message.emit(errorMessage)
            }
        }
    }

    @Callable
    func start_focus_block() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            let noApps = self.selection.applicationTokens.isEmpty
            let noCats = self.selection.categories.isEmpty
            let noWebs = self.selection.webDomains.isEmpty

            if noApps && noCats && noWebs {
                self.output_message.emit("Error: No apps, categories, or websites selected.")
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
                self.store.shield.applications = noApps ? nil : self.selection.applicationTokens
                
                // Both web domains and app categories have a special token format they expect
                let webDomainTokens: Set<WebDomainToken>? = noWebs ? nil : Set(self.selection.webDomains.compactMap { $0.token })
                self.store.shield.webDomains = webDomainTokens

                let categoryTokens: Set<ActivityCategoryToken>? = noCats ? nil : Set(self.selection.categories.compactMap { $0.token })
                self.store.shield.applicationCategories = categoryTokens.map { .specific($0) }

                GD.print("Block started for 1 hour.")
                self.output_message.emit("Block started for 1 hour.")
                
            } catch {
                GD.print("Error starting block: \(error.localizedDescription)")
            }
        }
    }
    
    @Callable
    func stop_focus_block() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Turn off the shield
            self.store.shield.applications = nil
            self.store.shield.applicationCategories = nil
            self.store.shield.webDomains = nil  

            // Stop the timer
            let center = DeviceActivityCenter()
            center.stopMonitoring([self.focusActivity])
            
            GD.print("Block stopped manually.")
            self.output_message.emit("Block stopped manually.")
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