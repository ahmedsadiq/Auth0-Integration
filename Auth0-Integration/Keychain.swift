//
//  Keychain.swift
//  Auth0-Integration
//
//  Created by Ahmed Sadiq on 21/03/2024.
//

import Foundation
import SimpleKeychain

struct Keychain {
    let keychainServiceName = KeychainService.name
    var keychain: SimpleKeychain {
        SimpleKeychain(
            service: self.keychainServiceName,
            accessGroup: self.keychainServiceName)
    }
    enum Keys: String {
        case phoneNumber
    }
    static var phoneNumber: String? {
        get {
            let key = Keys.phoneNumber.rawValue
            return try? Keychain().keychain.string(forKey: key)
        }
        set {
            let key = Keys.phoneNumber.rawValue
            if let phoneNumber = newValue {
                try? Keychain().keychain.set(phoneNumber, forKey: key)
            }
        }
    }
}
