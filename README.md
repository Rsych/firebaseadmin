# Firebase Admin for Swift

Firebase Admin for Swift is a server-side Swift package that provides a simple interface to interact with Firebase services using the Firebase Admin SDK.

This repository uses [FirebaseAPI](https://github.com/1amageek/FirebaseAPI) for gRPC-based Firebase service integration.

## Features

- ✅ **Swift 6** compatible with strict concurrency
- 🔥 **Firestore** - Full CRUD operations, queries, transactions, and batch writes
- 🔐 **Firebase Auth** - User management and authentication
- 📨 **Firebase Messaging** - Push notifications via FCM
- ✅ **AppCheck** - App attestation and verification
- 🌍 **Built-in types** - `Timestamp`, `GeoPoint`, `DocumentReference` support
- 📦 **Codable** - Native Swift Codable support with property wrappers
- 🔑 **Flexible authentication** - JSON file or environment variables

## Requirements

- Swift 6.2+
- macOS 15+ / iOS 18+
- Firebase project with service account credentials

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/1amageek/FirebaseAdmin.git", branch: "main")
]
```

## Configuration

Firebase Admin for Swift supports multiple ways to configure your service account credentials:

### Option 1: Environment Variables (Recommended for Production)

```bash
export FIREBASE_PROJECT_ID="your-project-id"
export FIREBASE_PRIVATE_KEY_ID="your-private-key-id"
export FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
export FIREBASE_CLIENT_EMAIL="firebase-adminsdk@your-project.iam.gserviceaccount.com"
export FIREBASE_CLIENT_ID="123456789012345678901"
```

```swift
import FirebaseApp

// Initialize from environment variables
try FirebaseApp.initializeFromEnvironment()
```

### Option 2: JSON File

```swift
import FirebaseApp

// Initialize from ServiceAccount.json file
FirebaseApp.initialize(fileName: "ServiceAccount")

// Or with custom path
let serviceAccount = try FirebaseApp.loadServiceAccount(from: "CustomServiceAccount")
FirebaseApp.initialize(serviceAccount: serviceAccount)
```

### Option 3: Hierarchical Configuration (Environment + JSON)

Environment variables take precedence over JSON file:

```swift
import FirebaseApp

// Environment variables override JSON values
try await FirebaseApp.initializeFromConfiguration(jsonPath: "config/firebase.json")
```

## Usage

### Firestore Operations

```swift
import Firestore

struct User: Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var age: Int
    var createdAt: Timestamp
    var location: GeoPoint
}

let user = User(
    name: "John Doe",
    age: 30,
    createdAt: Timestamp(),
    location: GeoPoint(latitude: 37.7749, longitude: -122.4194)
)

// Create document
let ref = try Firestore.firestore()
    .collection("users")
    .document("user_id")

try await ref.setData(user)

// Read document
let snapshot = try await ref.getDocument(type: User.self)
print(snapshot?.name ?? "Not found")

// Query documents
let querySnapshot = try await Firestore.firestore()
    .collection("users")
    .where(field: "age", isGreaterThan: 25)
    .getDocuments()

// Transaction
try await Firestore.firestore().runTransaction { transaction in
    let snapshot = try await transaction.get(documentReference: ref)
    if let user = try? snapshot.data(as: User.self) {
        var updatedUser = user
        updatedUser.age += 1
        transaction.update(documentReference: ref, fields: ["age": updatedUser.age])
    }
}

// Batch write
let batch = try Firestore.firestore().batch()
batch.setData(data: ["name": "Alice"], forDocument: ref)
batch.updateData(fields: ["age": 31], forDocument: ref)
try await batch.commit()
```

### Firebase Auth

```swift
import FirebaseAuth

let auth = FirebaseAuth()

// Get user by ID
let user = try await auth.getUser(uid: "user_id")

// List users
let users = try await auth.listUsers(maxResults: 100)

// Create custom token
let token = try await auth.createCustomToken(uid: "user_id", claims: ["admin": true])
```

### Firebase Messaging

```swift
import FirebaseMessaging

let messaging = try FirebaseMessaging()

let message = Message(
    token: "device_token",
    notification: Notification(
        title: "Hello",
        body: "World"
    )
)

let messageId = try await messaging.send(message: message)
```

## Built-in Type Support

### Timestamp
Represents a point in time with nanosecond precision:

```swift
let now = Timestamp()
let specific = Timestamp(seconds: 1609459200, nanos: 0)
let fromDate = Timestamp(date: Date())
```

### GeoPoint
Represents geographical coordinates:

```swift
let location = GeoPoint(latitude: 37.7749, longitude: -122.4194)
```

### DocumentReference
Represents a reference to a Firestore document:

```swift
let userRef = try Firestore.firestore().document("users/user_id")
```

## Property Wrappers

### @DocumentID
Automatically populates with the document ID when decoding:

```swift
struct User: Codable {
    @DocumentID var id: String?
    var name: String
}
```

**Note:** `@DocumentID` is not saved as a field in Firestore. It's only populated during decoding.

### @ExplicitNull
Explicitly sets a field to `null` in Firestore:

```swift
struct User: Codable {
    var name: String
    @ExplicitNull var age: Int?
}

var user = User(name: "John", age: 30)
user.age = nil // This will set the field to null in Firestore
```

## Testing

This project uses **Swift Testing** framework (not XCTest).

### Running Tests

```bash
# Run all tests (unit tests only, integration tests are disabled)
swift test

# Run specific test suite
swift test --filter FirebaseAppTests
```

### Test Structure

- **Unit Tests** (✅ Enabled) - No Firebase credentials required
  - `FirebaseAppTests` - ServiceAccount initialization and configuration
  - `AppCheckTests` - AppCheck functionality

- **Integration Tests** (⏭️ Disabled by default) - Require actual Firebase credentials
  - `FirestoreTests` - Firestore path operations
  - `DocumentTests` - Document CRUD operations
  - `WhereQueryTests` - Query operations
  - `RangeQueryTests` - Range and composite queries
  - `TransactionTests` - Transaction operations
  - `WriteBatchTests` - Batch write operations

### Running Integration Tests

1. Add valid `ServiceAccount.json` to project root, or set environment variables
2. Remove `.disabled()` from test suites in `Tests/FirestoreTests/`
3. Run tests:

```bash
swift test
```

## Vapor Integration

Example Vapor 4 integration:

```swift
// Package.swift
let package = Package(
    name: "VaporApp",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
        .package(url: "https://github.com/1amageek/FirebaseAdmin.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "FirebaseApp", package: "FirebaseAdmin"),
                .product(name: "Firestore", package: "FirebaseAdmin"),
                .product(name: "FirebaseAuth", package: "FirebaseAdmin"),
            ]
        )
    ]
)
```

```swift
// configure.swift
import Vapor
import FirebaseApp

public func configure(_ app: Application) async throws {
    // Initialize Firebase from environment variables
    try FirebaseApp.initializeFromEnvironment()

    // Register routes
    try routes(app)
}
```

## Development

### Prerequisites

1. **Service Account JSON** - Download from [Firebase Console](https://console.firebase.google.com/)
   - Go to Project Settings → Service Accounts
   - Generate new private key
   - Save as `ServiceAccount.json`

2. **Place the file** in project root:
   ```
   FirebaseAdmin/
   ├── ServiceAccount.json  (gitignored)
   ├── Package.swift
   └── ...
   ```

### Security Notes

⚠️ **Never commit service account credentials to version control!**

The `.gitignore` file already excludes:
- `ServiceAccount.json`
- `**/ServiceAccount.json`
- `firebase-adminsdk-*.json`
- `.env` files

### Environment Variables Setup

For production deployment, use environment variables:

```bash
# Example .env file (gitignored)
FIREBASE_PROJECT_ID=my-project
FIREBASE_PRIVATE_KEY_ID=abc123...
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@my-project.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=123456789012345678901
```

## Architecture

- **FirebaseApp** - Core initialization and service account management
- **Firestore** - Firestore database operations with gRPC
- **FirebaseAuth** - User authentication and management
- **FirebaseMessaging** - Cloud messaging
- **AppCheck** - App attestation

### Concurrency

This library is built with Swift 6 strict concurrency:
- Thread-safe with `Sendable` conformance
- Uses `Mutex<T>` for synchronization
- Async/await throughout

## License

See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Links

- [FirebaseAPI](https://github.com/1amageek/FirebaseAPI) - gRPC client generation
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Swift Configuration](https://github.com/apple/swift-configuration)
