//
//  FirebaseAuth.swift
//
//
//  Created by Vamsi Madduluri on 04/07/24.
//

import Foundation
import Synchronization
import AsyncHTTPClient
@_exported import FirebaseApp

// MARK: - Auth Factory

/// Internal factory for managing AuthClient instances per app
internal final class AuthClientFactory: Sendable {
    static let shared = AuthClientFactory()

    private let cache = Mutex<[String: AuthClient]>([:])

    private init() {}

    func getOrCreate(for app: FirebaseApp) -> AuthClient {
        return cache.withLock { cache in
            // Return cached instance if available
            if let cached = cache[app.name] {
                return cached
            }

            // Create new instance
            let authClient = AuthClient(serviceAccount: app.serviceAccount)
            cache[app.name] = authClient
            return authClient
        }
    }

    func clear(for appName: String) {
        cache.withLock { cache in
            cache.removeValue(forKey: appName)
        }
    }

    func clearAll() {
        cache.withLock { cache in
            cache.removeAll()
        }
    }
}

// MARK: - FirebaseApp Extension

/**
 Extension providing Auth factory method on FirebaseApp.
 */
extension FirebaseApp {

    /**
     Returns an `AuthClient` instance for this app.

     Use this method to obtain an `AuthClient` instance that is initialized with this app's
     service account. The instance is cached per app, so subsequent calls return the same instance.

     Example:
     ```swift
     let app = try FirebaseApp.initialize(serviceAccount: serviceAccount)
     let auth = app.auth()
     ```

     - Returns: An `AuthClient` instance initialized with this app's service account.
     */
    public func auth() -> AuthClient {
        return AuthClientFactory.shared.getOrCreate(for: self)
    }
}

// MARK: - FirebaseAuth

/**
 A class that provides convenient access to Firebase Authentication.

 The `FirebaseAuth` class provides static methods for accessing AuthClient instances
 from FirebaseApp instances.
 */
public class FirebaseAuth {

    /**
     Returns an `AuthClient` instance initialized with the default `FirebaseApp` instance.

     This is a convenience method that gets the default FirebaseApp and returns its AuthClient instance.

     Example:
     ```swift
     // Initialize default app first
     try FirebaseApp.initialize(serviceAccount: serviceAccount)

     // Get Auth from default app
     let auth = try FirebaseAuth.auth()
     ```

     - Returns: An `AuthClient` instance initialized with the default `FirebaseApp` instance.
     - Throws: Error if default app is not initialized
     */
    public static func auth() throws -> AuthClient {
        let app = try FirebaseApp.app()
        return app.auth()
    }

    /**
     Returns an `AuthClient` instance for the specified app.

     - Parameter app: The `FirebaseApp` instance to use for authenticating with Firebase.
     - Returns: An `AuthClient` instance initialized with the app's service account.
     */
    public static func auth(app: FirebaseApp) -> AuthClient {
        return app.auth()
    }
}
