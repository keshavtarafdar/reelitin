// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftGodot

#initSwiftExtension(
    cdecl: "swift_entry_point",
    types: [GodotPlugin.self]
)

@Godot
class GodotPlugin: RefCounted {
   
    // 1. Signal to send a string from Swift to Godot
    // The macro handles registration automatically.
    // It will be named "output_message" in Godot.
    @Signal var outputMessage: Signal1<String>

    // Callable method that Godot can call to send a string to Swift
    @Callable
    func sendMessageToSwift(message: String) -> String {
        print("Received message in Swift: \(message)")
        // You can process the received string here
        let response = "Swift processed: " + message
        
        return response // Return a value back to the caller in Godot
    }

    // Callable method that Godot can call to prompt Swift to send a signal
    @Callable
    func triggerSwiftSignal() {
        print("Godot called triggerSwiftSignal, emitting outputMessage signal...")
        // Emit the signal with the string data
        emit(signal: outputMessage, "Hello from Swift via signal!")
    }
}
