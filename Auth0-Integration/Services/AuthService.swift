//
//  AuthService.swift
//  Auth0-Integration
//
//  Created by Ahmed Sadiq on 21/03/2024.
//

import UIKit
import Auth0
import JWTDecode
import SimpleKeychain

protocol TokenService {
    func getToken(_ handler: ((Credentials?) -> Void)?)
}

protocol JWTService {
    func getJWT(_ handler: ((JWT?) -> Void)?)
}

class AuthService {
    static let shared = AuthService()
    private let udid = UIDevice.current.identifierForVendor?.uuidString
    private let config: Tennants
    
    private var authentication: Authentication {
        return Auth0.authentication(clientId: config.clientID, domain: config.domain)
    }
    
    lazy var credentialsManager: CredentialsManager = {
        CredentialsManager(
            authentication: self.authentication,
            storage: SimpleKeychain(
                service: KeychainService.name,
                accessGroup: KeychainService.name))
    }()
    
    var isLoggedIn: Bool {
        return Keychain.phoneNumber != nil
    }
    
    // MARK: - Methods -
    private init(config: Tennants = .dev) {
        self.config = config
    }
    
    func logout(_ completion: (() -> Void)? = nil) {
        if credentialsManager.clear() {
            _ = Keychain().keychain.deleteEntry(forKey: Keychain.Keys.phoneNumber.rawValue)
            completion?()
        }
    }
    
    func decodeToken(_ token: String) -> JWT? {
        let jwt = try? decode(jwt: token)
        return jwt
    }
    
    func credentials(handler: ((Auth0.Credentials?) -> Void)?) {
        self.credentialsManager.credentials(minTTL: 5) { result in
            switch result {
            case .success(let credentials):
                handler?(credentials)
            case .failure(let error):
                print(error.localizedDescription)
                handler?(nil)
            }
        }
    }
    
    func login(_ smartLinkUUID: String="", _ promptLogin: Bool=false, _ handler: ((Credentials) -> Void)?) {
        var params = [
            AuthParams.phone.rawValue: Keychain.phoneNumber ?? "",
            AuthParams.udid.rawValue: self.udid ?? "",
            AuthParams.pushChannelID.rawValue: "your_push_channel_id"
        ]
        if !smartLinkUUID.isEmpty {
            params[AuthParams.smartLinkUUID.rawValue] = smartLinkUUID
        }
        if promptLogin {
            params["prompt"] = "login"
        }
        print("Parameters are", params)
        Auth0
            .webAuth(clientId: config.clientID, domain: config.domain)
            .useEphemeralSession()
            .scope(Scopes.authScopes)
            .audience(config.audience)
            .parameters(params)
            .start { result in
                switch result {
                case let .success(credentials):
                    let temp = AuthParams.phone.rawValue
                    Auth0
                        .authentication()
                        .userInfo(withAccessToken: credentials.accessToken)
                        .start { result in
                            switch result {
                            case .success(let profile):
                                Keychain.phoneNumber = profile.name!
                            case .failure(let error):
                                // Handle the error
                                print(error.localizedDescription)
                            }
                            handler?(credentials)
                        }
                    if self.credentialsManager.store(credentials: credentials) {
                        print("Stored credentials")
                    }
                case let .failure(error):
                    print("Failed with \(error.localizedDescription)")
                }
            }
    }
    
}
extension AuthService {
    private enum Scopes: String, CaseIterable {
        case openid
        case profile
        case email
        case offlineAccess = "offline_access"
        static var authScopes: String {
            return Scopes.allCases.map { $0.rawValue }.joined(separator: " ")
        }
    }
    private enum Tennants {
        case dev
        case prod
        var domain: String {
            return "Your_auth0_domain"
        }
        var clientID: String {
            return "your_auth0_clientID"
        }
        var audience: String {
            return "your_auth0_audience"
        }
    }
    enum AuthParams: String {
        case phone
        case udid
        case pushChannelID = "push_channel_id"
        case smartLinkUUID = "smart_link_uuid"
    }
}
extension AuthService: TokenService, JWTService {
    
    func getToken(_ handler: ((Auth0.Credentials?) -> Void)?) {
        self.credentials { creds in
            handler?(creds)
        }
    }
    
    func getJWT(_ handler: (((any JWTDecode.JWT)?) -> Void)?) {
        self.getToken { creds in
            guard let token = creds?.idToken else {
                handler?(nil)
                return
            }
            print(token)
            let jwt = self.decodeToken(token)
            handler?(jwt)
        }
    }
}
