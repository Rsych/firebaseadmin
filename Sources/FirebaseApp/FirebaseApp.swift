//
//  FirebaseApp.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/07.
//

import Foundation
import Synchronization

// MARK: - Errors

/// Errors that can occur when working with FirebaseApp
public enum FirebaseAppError: Error, CustomStringConvertible {
    case duplicateApp(name: String)
    case noApp(name: String)
    case serviceAccountNotInitialized

    public var description: String {
        switch self {
        case .duplicateApp(let name):
            return "FirebaseApp named '\(name)' has already been initialized."
        case .noApp(let name):
            return "FirebaseApp named '\(name)' does not exist. Call FirebaseApp.initialize(name:serviceAccount:) before using it."
        case .serviceAccountNotInitialized:
            return "Service Account is not initialized. Call FirebaseApp.initialize() first."
        }
    }
}

// MARK: - FirebaseApp

/// Firebase application instance that manages service access and lifecycle.
///
/// FirebaseApp serves as the entry point for all Firebase services (Firestore, Auth, Messaging, AppCheck).
/// It supports multiple named instances, allowing connections to different Firebase projects simultaneously.
///
/// ## Basic Usage
///
/// Initialize the default app:
/// ```swift
/// let serviceAccount = try ServiceAccount.load(from: "ServiceAccount.json")
/// let app = try FirebaseApp.initialize(serviceAccount: serviceAccount)
/// ```
///
/// Use services from the app:
/// ```swift
/// let firestore = try app.firestore()
/// let auth = try app.auth()
/// let messaging = try app.messaging()
/// ```
///
/// ## Multiple Projects
///
/// Connect to multiple Firebase projects:
/// ```swift
/// let defaultApp = try FirebaseApp.initialize(
///     name: FirebaseApp.defaultName,
///     serviceAccount: account1
/// )
/// let secondaryApp = try FirebaseApp.initialize(
///     name: "secondary",
///     serviceAccount: account2
/// )
///
/// let firestore1 = try defaultApp.firestore()
/// let firestore2 = try secondaryApp.firestore()
/// ```
///
/// ## Lifecycle Management
///
/// Delete an app when no longer needed:
/// ```swift
/// try app.delete()
/// ```
public final class FirebaseApp: Sendable {

    // MARK: - Properties

    /// The unique name of this app instance
    public let name: String

    /// The service account used for authentication
    public let serviceAccount: ServiceAccount

    // MARK: - Static Properties

    /// Default app instance name
    public static let defaultName = "[DEFAULT]"

    /// Registry of all app instances (thread-safe with Mutex)
    private static let instances = Mutex<[String: FirebaseApp]>([:])

    // MARK: - Initialization

    /// Private initializer - use static initialize() methods instead
    private init(name: String, serviceAccount: ServiceAccount) {
        self.name = name
        self.serviceAccount = serviceAccount
    }

    // MARK: - App Lifecycle

    /// Initialize a new FirebaseApp instance.
    ///
    /// - Parameters:
    ///   - name: Unique name for this app instance (defaults to "[DEFAULT]")
    ///   - serviceAccount: Service account for Firebase authentication
    /// - Returns: The initialized FirebaseApp instance
    /// - Throws: `FirebaseAppError.duplicateApp` if an app with this name already exists
    @discardableResult
    public static func initialize(
        name: String = defaultName,
        serviceAccount: ServiceAccount
    ) throws -> FirebaseApp {
        return try instances.withLock { instances in
            // Check if app already exists
            if instances[name] != nil {
                throw FirebaseAppError.duplicateApp(name: name)
            }

            let app = FirebaseApp(name: name, serviceAccount: serviceAccount)
            instances[name] = app
            return app
        }
    }

    /// Initialize from a JSON file.
    ///
    /// - Parameters:
    ///   - name: Unique name for this app instance (defaults to "[DEFAULT]")
    ///   - fileName: Name of the JSON file (without .json extension)
    /// - Returns: The initialized FirebaseApp instance
    /// - Throws: Error if file not found or JSON parsing fails
    @discardableResult
    public static func initialize(
        name: String = defaultName,
        fileName: String = "ServiceAccount"
    ) throws -> FirebaseApp {
        let serviceAccount = try loadServiceAccount(from: fileName)
        return try initialize(name: name, serviceAccount: serviceAccount)
    }

    /// Initialize from environment variables.
    ///
    /// Reads Firebase service account configuration from environment variables:
    /// - `FIREBASE_PROJECT_ID`
    /// - `FIREBASE_PRIVATE_KEY_ID`
    /// - `FIREBASE_PRIVATE_KEY`
    /// - `FIREBASE_CLIENT_EMAIL`
    /// - `FIREBASE_CLIENT_ID`
    ///
    /// - Parameter name: Unique name for this app instance (defaults to "[DEFAULT]")
    /// - Returns: The initialized FirebaseApp instance
    /// - Throws: Error if environment variables are not set or invalid
    @discardableResult
    public static func initializeFromEnvironment(name: String = defaultName) throws -> FirebaseApp {
        let serviceAccount = try ServiceAccount.loadFromEnvironment()
        return try initialize(name: name, serviceAccount: serviceAccount)
    }

    /// Initialize with hierarchical configuration (async).
    ///
    /// Priority order:
    /// 1. Environment variables (highest)
    /// 2. JSON file (if provided)
    ///
    /// - Parameters:
    ///   - name: Unique name for this app instance (defaults to "[DEFAULT]")
    ///   - jsonPath: Optional path to JSON file
    /// - Returns: The initialized FirebaseApp instance
    @discardableResult
    public static func initializeFromConfiguration(
        name: String = defaultName,
        jsonPath: String? = nil
    ) async throws -> FirebaseApp {
        let serviceAccount = try await ServiceAccount.loadFromConfiguration(jsonPath: jsonPath)
        return try initialize(name: name, serviceAccount: serviceAccount)
    }

    /// Get an existing FirebaseApp instance by name.
    ///
    /// - Parameter name: Name of the app instance (defaults to "[DEFAULT]")
    /// - Returns: The FirebaseApp instance
    /// - Throws: `FirebaseAppError.noApp` if no app with this name exists
    public static func app(name: String = defaultName) throws -> FirebaseApp {
        return try instances.withLock { instances in
            guard let app = instances[name] else {
                throw FirebaseAppError.noApp(name: name)
            }
            return app
        }
    }

    /// Get all FirebaseApp instances.
    ///
    /// - Returns: Dictionary mapping app names to FirebaseApp instances
    public static func allApps() -> [String: FirebaseApp] {
        return instances.withLock { instances in
            return instances
        }
    }

    /// Delete this FirebaseApp instance.
    ///
    /// Removes the app from the registry. Services created from this app may continue
    /// to work, but you won't be able to retrieve this app instance again.
    ///
    /// - Throws: Error if deletion fails
    public func delete() throws {
        _ = Self.instances.withLock { instances in
            instances.removeValue(forKey: name)
        }
    }

    /// Delete all FirebaseApp instances.
    ///
    /// Useful for testing and cleanup.
    public static func deleteAll() {
        instances.withLock { instances in
            instances.removeAll()
        }
    }

    // MARK: - Helper Methods

    /// Load ServiceAccount from JSON file in Bundle.main
    ///
    /// - Parameter jsonFile: Name of the JSON file (without .json extension)
    /// - Returns: Decoded ServiceAccount
    /// - Throws: Error if file not found or JSON parsing fails
    public static func loadServiceAccount(from jsonFile: String) throws -> ServiceAccount {
        guard let path = Bundle.main.path(forResource: jsonFile, ofType: "json") else {
            throw NSError(
                domain: "FileNotFoundError",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "JSON file '\(jsonFile).json' not found in Bundle.main"]
            )
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let decoder = JSONDecoder()
        return try decoder.decode(ServiceAccount.self, from: data)
    }

    /// Get the service account for this app.
    ///
    /// - Returns: The service account
    /// - Throws: `FirebaseAppError.serviceAccountNotInitialized` if not initialized
    public func getServiceAccount() throws -> ServiceAccount {
        return serviceAccount
    }
}
