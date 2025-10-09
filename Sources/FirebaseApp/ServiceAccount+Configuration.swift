//
//  ServiceAccount+Configuration.swift
//
//
//  Created by Claude Code on 2025/10/08.
//

import Foundation
import Configuration
import SystemPackage

extension ServiceAccount {
    /// Configuration keys for Firebase service account
    public enum ConfigKey {
        public static let projectId = "firebase.projectId"
        public static let privateKeyId = "firebase.privateKeyId"
        public static let privateKey = "firebase.privateKey"
        public static let clientEmail = "firebase.clientEmail"
        public static let clientId = "firebase.clientId"
        public static let authUri = "firebase.authUri"
        public static let tokenUri = "firebase.tokenUri"
        public static let authProviderX509CertUrl = "firebase.authProviderX509CertUrl"
        public static let clientX509CertUrl = "firebase.clientX509CertUrl"
    }

    /// Load ServiceAccount from environment variables
    ///
    /// Environment variables are automatically transformed:
    /// - `firebase.projectId` → `FIREBASE_PROJECT_ID`
    /// - `firebase.clientEmail` → `FIREBASE_CLIENT_EMAIL`
    ///
    /// Example:
    /// ```bash
    /// export FIREBASE_PROJECT_ID="my-project"
    /// export FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----..."
    /// export FIREBASE_CLIENT_EMAIL="firebase-adminsdk@my-project.iam.gserviceaccount.com"
    /// export FIREBASE_CLIENT_ID="123456789"
    /// export FIREBASE_PRIVATE_KEY_ID="key-id"
    /// ```
    ///
    /// ```swift
    /// let serviceAccount = try ServiceAccount.loadFromEnvironment()
    /// FirebaseApp.initialize(serviceAccount: serviceAccount)
    /// ```
    public static func loadFromEnvironment() throws -> ServiceAccount {
        let config = ConfigReader(provider: EnvironmentVariablesProvider())

        guard let projectId = config.string(forKey: ConfigKey.projectId),
              let privateKeyId = config.string(forKey: ConfigKey.privateKeyId),
              let privateKey = config.string(forKey: ConfigKey.privateKey),
              let clientEmail = config.string(forKey: ConfigKey.clientEmail),
              let clientId = config.string(forKey: ConfigKey.clientId) else {
            throw ConfigurationError.missingRequiredFields
        }

        // Optional fields with sensible defaults
        let authUri = config.string(
            forKey: ConfigKey.authUri,
            default: "https://accounts.google.com/o/oauth2/auth"
        )
        let tokenUri = config.string(
            forKey: ConfigKey.tokenUri,
            default: "https://oauth2.googleapis.com/token"
        )
        let authProviderX509CertUrl = config.string(
            forKey: ConfigKey.authProviderX509CertUrl,
            default: "https://www.googleapis.com/oauth2/v1/certs"
        )
        let clientX509CertUrl = config.string(
            forKey: ConfigKey.clientX509CertUrl,
            default: "https://www.googleapis.com/robot/v1/metadata/x509/\(clientEmail)"
        )

        return ServiceAccount(
            type: "service_account",
            projectId: projectId,
            privateKeyId: privateKeyId,
            privateKeyPem: privateKey.replacingOccurrences(of: "\\n", with: "\n"),
            clientEmail: clientEmail,
            clientId: clientId,
            authUri: authUri,
            tokenUri: tokenUri,
            authProviderX509CertUrl: authProviderX509CertUrl,
            clientX509CertUrl: clientX509CertUrl
        )
    }

    /// Load ServiceAccount with hierarchical configuration
    ///
    /// Priority order:
    /// 1. Environment variables (highest)
    /// 2. JSON file (if provided)
    ///
    /// Example:
    /// ```swift
    /// let serviceAccount = try await ServiceAccount.loadFromConfiguration(
    ///     jsonPath: "config/firebase.json"
    /// )
    /// ```
    public static func loadFromConfiguration(jsonPath: String? = nil) async throws -> ServiceAccount {
        let config: ConfigReader

        if let jsonPath = jsonPath {
            let jsonProvider = try await JSONProvider(filePath: FilePath(jsonPath))
            config = ConfigReader(providers: [
                EnvironmentVariablesProvider(),
                jsonProvider
            ])
        } else {
            config = ConfigReader(provider: EnvironmentVariablesProvider())
        }

        guard let projectId = config.string(forKey: ConfigKey.projectId),
              let privateKeyId = config.string(forKey: ConfigKey.privateKeyId),
              let privateKey = config.string(forKey: ConfigKey.privateKey),
              let clientEmail = config.string(forKey: ConfigKey.clientEmail),
              let clientId = config.string(forKey: ConfigKey.clientId) else {
            throw ConfigurationError.missingRequiredFields
        }

        let authUri = config.string(
            forKey: ConfigKey.authUri,
            default: "https://accounts.google.com/o/oauth2/auth"
        )
        let tokenUri = config.string(
            forKey: ConfigKey.tokenUri,
            default: "https://oauth2.googleapis.com/token"
        )
        let authProviderX509CertUrl = config.string(
            forKey: ConfigKey.authProviderX509CertUrl,
            default: "https://www.googleapis.com/oauth2/v1/certs"
        )
        let clientX509CertUrl = config.string(
            forKey: ConfigKey.clientX509CertUrl,
            default: "https://www.googleapis.com/robot/v1/metadata/x509/\(clientEmail)"
        )

        return ServiceAccount(
            type: "service_account",
            projectId: projectId,
            privateKeyId: privateKeyId,
            privateKeyPem: privateKey.replacingOccurrences(of: "\\n", with: "\n"),
            clientEmail: clientEmail,
            clientId: clientId,
            authUri: authUri,
            tokenUri: tokenUri,
            authProviderX509CertUrl: authProviderX509CertUrl,
            clientX509CertUrl: clientX509CertUrl
        )
    }
}

/// Configuration errors
public enum ConfigurationError: Error, LocalizedError {
    case missingRequiredFields
    case invalidConfiguration

    public var errorDescription: String? {
        switch self {
        case .missingRequiredFields:
            return """
            Missing required Firebase configuration fields.
            Required environment variables:
            - FIREBASE_PROJECT_ID
            - FIREBASE_PRIVATE_KEY_ID
            - FIREBASE_PRIVATE_KEY
            - FIREBASE_CLIENT_EMAIL
            - FIREBASE_CLIENT_ID
            """
        case .invalidConfiguration:
            return "Invalid Firebase configuration"
        }
    }
}
