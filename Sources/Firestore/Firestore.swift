import Foundation
import Synchronization
@_exported import FirestoreAPI
@_exported import FirebaseApp
@_exported import GRPCNIOTransportHTTP2

/**
 A typealias for Firestore with HTTP2 transport using NIO.

 This is the default transport implementation for Firestore.
 */
public typealias FirestoreHTTP2 = Firestore<HTTP2ClientTransport.Posix>

// MARK: - Firestore Factory

/// Internal factory for managing Firestore instances per app
internal final class FirestoreFactory: Sendable {
    static let shared = FirestoreFactory()

    private let cache = Mutex<[String: Firestore<HTTP2ClientTransport.Posix>]>([:])

    private init() {}

    func getOrCreate(for app: FirebaseApp) throws -> Firestore<HTTP2ClientTransport.Posix> {
        return try cache.withLock { cache in
            // Return cached instance if available
            if let cached = cache[app.name] {
                return cached
            }

            // Create new instance
            let firestore = try createFirestore(for: app)
            cache[app.name] = firestore
            return firestore
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

    private func createFirestore(for app: FirebaseApp) throws -> Firestore<HTTP2ClientTransport.Posix> {
        let transport = try HTTP2ClientTransport.Posix(
            target: .dns(host: "firestore.googleapis.com", port: 443),
            transportSecurity: .tls,
            config: .defaults(configure: { $0.http2.targetWindowSize = 65535 })
        )

        let accessTokenProvider = try AccessTokenProvider(serviceAccount: app.serviceAccount)

        let firestore = Firestore(
            projectId: app.serviceAccount.projectId,
            transport: transport,
            accessTokenProvider: accessTokenProvider
        )

        return firestore
    }
}

// MARK: - FirebaseApp Extension

/**
 Extension providing Firestore factory method on FirebaseApp.
 */
extension FirebaseApp {

    /**
     Returns a `Firestore` instance for this app.

     Use this method to obtain a `Firestore` instance that is initialized with this app's
     service account. The instance is cached per app, so subsequent calls return the same instance.

     Example:
     ```swift
     let app = try FirebaseApp.initialize(serviceAccount: serviceAccount)
     let firestore = try app.firestore()
     ```

     - Returns: A `Firestore` instance initialized with this app's service account.
     - Throws: Error if Firestore initialization fails
     */
    public func firestore() throws -> Firestore<HTTP2ClientTransport.Posix> {
        return try FirestoreFactory.shared.getOrCreate(for: self)
    }
}

// MARK: - Convenience Methods

/**
 Extension providing convenience methods for creating Firestore instances.
 */
extension Firestore where Transport == HTTP2ClientTransport.Posix {

    /**
     A struct that represents an access scope for the Firestore database.

     The `Scope` struct conforms to the `AccessScope` protocol and provides a single read-only property that returns the URL for the access scope required for accessing the Firestore database.
     */
    struct Scope: FirestoreAPI.AccessScope {

        /// The URL for the access scope required for accessing the Firestore database.
        public var value: String { "https://www.googleapis.com/auth/cloud-platform" }
    }

    /**
     Returns a `Firestore` instance initialized with the default `FirebaseApp` instance.

     This is a convenience method that gets the default FirebaseApp and returns its Firestore instance.

     Example:
     ```swift
     // Initialize default app first
     try FirebaseApp.initialize(serviceAccount: serviceAccount)

     // Get Firestore from default app
     let firestore = try Firestore.firestore()
     ```

     - Returns: A `Firestore` instance initialized with the default `FirebaseApp` instance.
     - Throws: Error if default app is not initialized or Firestore creation fails
     */
    public static func firestore() throws -> Firestore<HTTP2ClientTransport.Posix> {
        let app = try FirebaseApp.app()
        return try app.firestore()
    }

    /**
     Returns a `Firestore` instance for the specified app.

     - Parameter app: The `FirebaseApp` instance to use
     - Returns: A `Firestore` instance initialized with the app's service account
     - Throws: Error if Firestore creation fails
     */
    public static func firestore(app: FirebaseApp) throws -> Firestore<HTTP2ClientTransport.Posix> {
        return try app.firestore()
    }

    /**
     Retrieves an access token for the Firestore database.

     Use this method to retrieve an access token for the Firestore database. If an access token has already been retrieved, this method returns it. Otherwise, it initializes an `AccessTokenProvider` instance with the `FirebaseApp` service account and retrieves a new access token using the `Scope` struct. The access token is then stored in the `accessToken` property of the `Firestore` instance and returned.

     - Returns: An access token for the Firestore database.
     - Throws: A `ServiceAccountError` if an error occurs while initializing the `AccessTokenProvider` instance or retrieving the access token.
     */
    func getAccessToken() async throws -> String? {
        return try await accessTokenProvider?.getAccessToken(expirationDuration: 3600)
    }
}
