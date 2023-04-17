import Foundation
import CryptoKit
import LocalAuthentication

/// The unencrypted plain text.
let unencrypted = "Howdy, partners!"

/// Starts the ``encryptionTest()`` function from a UI button press.
func runEncryptionTest(onDone: @escaping (_ success: Bool, _ message: String?) -> Void) {
    Task { @MainActor in
        var success: Bool = false
        var message: String?
        
        do {
            (success, message) = try await encryptionTest()
        } catch {}
        
        onDone(success, message)
    }
}

/// Perform the encryption demo.
func encryptionTest() async throws -> (Bool, String?) {
    // Create the access control instance.
    let accessControl = SecAccessControlCreateWithFlags(
        // Use default allocator.
        nil,
        // Require password to be set, and tied to the device.
        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
        // Permit any enrolled biometrics on the device to use the private key.
        [.biometryAny, .privateKeyUsage],
        // Not handling CF Error.
        nil
    )!
    
    // Create and evaluate an authContext. The same one is used for simplicity
    // you may, however, use multiple.
    let authContext = try! await createAuthContext(reason: "decrypt your data", mustEvaluate: true)

    // Use CryptoKit to generate the key.
    let ckPrivateKey = try await SecureEnclave.P256.Signing.PrivateKey(
        compactRepresentable: false,
        accessControl: accessControl,
        authenticationContext: createAuthContext()
    )
    
    // Now convert to a SecKey.
    let sfPrivateKey: SecKey = SecKeyCreateWithData(ckPrivateKey.dataRepresentation as NSData, [
        // All SecureEnclave keys have the following properties.
        kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeySizeInBits: 256,
        kSecAttrKeyClass: kSecAttrKeyClassPrivate,
        kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,

        // You can probably omit these if you wish.
        kSecAttrIsPermanent: true,
        kSecAttrIsExtractable: false,

        // Controls whether the key should be synchronized between
        // devices.
        // Probably false, as that's the point of the Secure Enclave.
        kSecAttrSynchronizable: false,

        // Pass these as you did to CryptoKit.
        kSecAttrAccessControl: accessControl,
        kSecUseAuthenticationContext: authContext,
    ] as NSDictionary, nil)!

    // Should work and print a SecKeyRef.
    print(sfPrivateKey)

    // Should also work.
    let sfPublicKey: SecKey = SecKeyCopyPublicKey(sfPrivateKey)!

    let sfPublicKeyRep = SecKeyCopyExternalRepresentation(sfPublicKey, nil)! as NSData
    print(sfPublicKeyRep)
//    print(ckPublicKey.x963Representation as NSData)

    // Attempted encryption and decryption
    let encryptedData = SecKeyCreateEncryptedData(
        sfPublicKey,
        .eciesEncryptionCofactorX963SHA256AESGCM,
        unencrypted.data(using: .utf8)! as CFData,
        nil
    )! as NSData

    let decryptedData = SecKeyCreateDecryptedData(
        sfPrivateKey,
        .eciesEncryptionCofactorX963SHA256AESGCM,
        encryptedData as CFData,
        nil
    )! as Data

    // It works! ( Hopefully :) )
    let decryptedStr = (String(data: decryptedData as Data, encoding: .utf8)!)
    print(decryptedStr)
    print("Success: \(decryptedStr == unencrypted)")
    return (decryptedStr == unencrypted, decryptedStr)
}

// MARK: Helper functions.

private func createAuthContext(reason: String? = nil, fallbackTitle: String? = nil, mustEvaluate: Bool = false) async throws -> LAContext {
        // Create a Local Authentication context to control specifics about how authentication
        // works.
        let authContext = LAContext()
        
        // Permit a lock screen (and ONLY a lock screen) authentication to cause the application
        // to be unlocked for up to 5 seconds.
        authContext.touchIDAuthenticationAllowableReuseDuration = 5
        
        // Add localized fallback title that explains the purpose of entering the password.
        // (Users are going to have more resistance to entering a password versus biometric
        // authentication.)
        if (fallbackTitle != nil) { authContext.localizedFallbackTitle = fallbackTitle! }
        
        // Add additional contextual information.
        if (reason != nil) { authContext.localizedReason = reason! }
        
        if mustEvaluate {
            let evaluateAccessControlSuccess = (try await authContext.evaluateAccessControl(SecAccessControlCreateWithFlags(
                    // Use default allocator.
                    nil,
                    // Require password to be set, bind the key to the current device.
                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                    // Evalute any biometrics on the device.
                    .biometryAny,
                    // No error pointer specified for brevity.
                    nil
            )!, operation: .useKeyDecrypt, localizedReason: authContext.localizedReason))
            
            if (!evaluateAccessControlSuccess) {
                throw ExampleError(message: "Failed to authenticate biometrics.")
            }
        }
        
        return authContext
    }
