import SwiftUI

class ExampleError : NSObject, LocalizedError {
    let message: String;

    override var description: String {
        get {
            return "\(String(describing: type(of: self))): \(message)";
        }
    }

    var errorDescription: String? {
        return description;
    }

    init(message: String) {
        self.message = message
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
