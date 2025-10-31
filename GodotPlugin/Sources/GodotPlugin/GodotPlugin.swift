// The Swift Programming Language
// https://docs.swift.org/swift-book
import SwiftGodot

#initSwiftExtension(
    cdecl: "swift_entry_point",
    types: [GodotPlugin.self]
)

@Godot
class GodotPlugin: RefCounted {
   
    // Define a signal with one argument (String)
    nonisolated(unsafe) static let output = SignalWith1Argument<String>("Output")

    @Callable
    func connectToGodot() -> String {
        emit(signal: Self.output, "Hello from Swift!")
        return "You are now focusing!"
    }
}
