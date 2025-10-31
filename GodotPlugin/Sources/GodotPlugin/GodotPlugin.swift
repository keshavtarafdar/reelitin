// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftGodot

#initSwiftExtension(
    cdecl: "swift_entry_point",
    types: [GodotPlugin.self]
)

@Godot
class GodotPlugin: RefCounted {
   
    // Instance signal
    nonisolated(unsafe) let output = SignalWith1Argument<String>("Output")

    @Callable
    func connectToGodot() -> String {
        emit(signal: output, "Hello from Swift!")
        return "You are now focusing!"
    }
}
