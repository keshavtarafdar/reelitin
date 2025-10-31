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
    @Signal var outputMessage: SignalWithArguments<String>

    // Callable: Godot → Swift
    @Callable
    func sendMessageToSwift(message: String) -> String {
        print("Received message in Swift: \(message)")
        return "Swift processed: \(message)"
    }

    // Callable: Godot calls this → Swift emits signal → Godot receives
    @Callable
    func triggerSwiftSignal() {
        print("Godot called triggerSwiftSignal, emitting outputMessage signal...")
        outputMessage.emit("This string came from a swift file!")
    }
}
