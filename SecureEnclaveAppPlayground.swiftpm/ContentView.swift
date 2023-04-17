import SwiftUI

struct ContentView: View {
    /// Reference to the ``UIViewController`` for the current View.
    @Environment(\.viewController) private var viewControllerHolder: UIViewController?
    
    /// Helper function to call ``runEncryptionTest(onDone:)`` and display the result in a dialog.
    func doRunEncryptionTest() {
        runEncryptionTest { success, result in
            let resultAlert = UIAlertController(
                title: success ? "Completed Successfully" : "Failed",
                message: success ? "The message was encrypted and decrypted successfully: \(result ?? String(describing: result))" : "There was a problem decrypting the message: \(result ?? String(describing: result))",
                preferredStyle: .alert
            )
            
            resultAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { UIAlertAction in }))
            
            self.viewControllerHolder?.present(resultAlert, animated: true)
        }
    }
    
    var body: some View {
        VStack {
            Image(systemName: "lock.rectangle.on.rectangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.accentColor)
                .frame(height: 48)
            
            Text("Secure Enclave CryptoKit Encryption Demo").font(.system(size: 24, weight: .black)).textCase(.uppercase).multilineTextAlignment(.center)
            
            Spacer().frame(height: 20)
            
            Button(action: doRunEncryptionTest) {
                HStack {
                    
                    Image(systemName: "play.fill")
                    
                    Text("Run").font(.system(size: 20))
                        
                }.padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8))
            }.buttonStyle(.borderedProminent)
             .tint(.accentColor)
             .cornerRadius(18)
             .padding(EdgeInsets(top: 20, leading: 55, bottom: 20, trailing: 55))
            
            Spacer().frame(height: 20)
            
            Text("This demo uses the Xcode developer console. It's not very interesting on a phone only!").multilineTextAlignment(.center)
        }
    }
}

// Source: https://stackoverflow.com/a/58970681/2872279
// Drop in method to get a UIViewController from a View.

struct ViewControllerHolder {
    weak var value: UIViewController?
}

struct ViewControllerKey: EnvironmentKey {
    static var defaultValue: ViewControllerHolder {
        return ViewControllerHolder(value: UIApplication.shared.windows.first?.rootViewController)

    }
}

extension EnvironmentValues {
    var viewController: UIViewController? {
        get { return self[ViewControllerKey.self].value }
        set { self[ViewControllerKey.self].value = newValue }
    }
}
