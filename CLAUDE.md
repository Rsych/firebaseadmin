# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

FirebaseAdmin is a Swift package that provides a server-side interface to Firebase services (Firestore, Auth, Messaging, AppCheck). It's designed for Swift server applications and follows Swift 6 concurrency patterns.

## Build & Test Commands

```bash
# Build the entire package
swift build

# Run all tests
swift test

# Run specific test target
swift test --filter FirestoreTests

# Run a single test
swift test --filter FirestoreTests.FirestoreTests/testPath
```

**Important**: Tests require a `ServiceAccount.json` file in the `Tests/FirestoreTests/` directory. This file contains Firebase project credentials and should never be committed to version control.

## Architecture

### Core Components

1. **FirebaseApp** (Sources/FirebaseApp/)
   - Singleton that manages the Firebase service account
   - Must be initialized before using any Firebase services via `FirebaseApp.initialize(serviceAccount:)`
   - Thread-safe using NSLock for concurrent access to service account

2. **FirebaseAPIClient** (Sources/FirebaseApp/FirebaseAPIClient.swift)
   - Handles OAuth2 authentication using JWT with RSA256 signing
   - Manages HTTP requests to Firebase APIs using AsyncHTTPClient
   - Uses SwiftNIO EventLoopFuture for async operations
   - OAuth token flow: Creates JWT from service account → exchanges for OAuth token → uses token in API requests

3. **Service Modules**
   - **Firestore**: Wraps googleapis/FirebaseAPI for document/collection operations, uses gRPC-style API with HPACK headers
   - **FirebaseAuth**: User authentication management via AuthClient
   - **FirebaseMessaging**: FCM message sending via MessagingClient
   - **AppCheck**: App attestation verification

### Authentication Flow

All services follow this pattern:
1. Get ServiceAccount from FirebaseApp singleton
2. Create JWT signed with service account's private key (RS256)
3. Exchange JWT for OAuth access token
4. Use OAuth token as Bearer token in API requests

### Firestore Integration

Firestore uses the FirebaseAPI package (github.com/1amageek/FirebaseAPI) which wraps Google's googleapis:
- DocumentReference and CollectionReference provide CRUD operations
- Built-in Codable support for Firestore types (Timestamp, GeoPoint, DocumentReference)
- Property wrappers: `@DocumentID` (auto-populated, not saved at top level), `@ExplicitNull` (explicit nil encoding)
- Access tokens obtained via AccessTokenProvider, attached as HPACK headers

### Concurrency

- Targets use Swift 6 strict concurrency (`StrictConcurrency=targeted` or `StrictConcurrency`)
- Upcoming features enabled: `DisableOutwardActorInference`, `SWIFT_UPCOMING_FEATURE_FORWARD_TRAILING_CLOSURES`
- FirebaseApp marked `@unchecked Sendable` with internal locking
- EventLoopFuture-based async operations (not async/await in FirebaseAPIClient)

## Package Structure

- **Products**: FirebaseApp, AppCheck, Firestore, FirebaseAuth, FirebaseMessaging
- **Key Dependencies**: AsyncHTTPClient (HTTP), JWTKit (auth), FirebaseAPI (Firestore), AnyCodable (Auth)
- **Platforms**: iOS 15+, macOS 10.15+

## Development Workflow

1. Add `ServiceAccount.json` to `Tests/FirestoreTests/` (obtain from Firebase Console)
2. The test targets use `Bundle.module.path(forResource:ofType:)` to load the service account
3. Initialize FirebaseApp in test setUp: `FirebaseApp.initialize(serviceAccount: serviceAccount)`
4. Use `try Firestore.firestore()` or `try FirebaseAuth.auth()` to get service instances

## Common Patterns

**Initialize app:**
```swift
let serviceAccount = try FirebaseApp.loadServiceAccount(from: "ServiceAccount")
FirebaseApp.initialize(serviceAccount: serviceAccount)
```

**Firestore operations:**
```swift
let firestore = try Firestore.firestore()
let ref = firestore.collection("users").document("userId")
try await ref.setData(userData)
let data = try await ref.getDocument(type: User.self)
```

**Auth operations:**
```swift
let auth = try FirebaseAuth.auth()
// Use auth client methods
```

**Messaging:**
```swift
let messaging = try FirebaseMessaging.getMessaging()
// Send FCM messages
```

## Important Notes

- ServiceAccount.json contains sensitive credentials - never commit it
- All async operations in FirebaseAPIClient use EventLoopFuture, not async/await
- Firestore uses HPACK headers (from NIOHPACK) for gRPC-style API communication
- The package re-exports FirebaseApp and FirestoreAPI types for convenience
