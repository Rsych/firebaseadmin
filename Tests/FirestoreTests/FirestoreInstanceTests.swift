import Testing
import Foundation
@testable import Firestore

@Suite("Firestore Instance Tests")
struct FirestoreInstanceTests {

    init() {
        initializeFirebaseForTesting()
    }

    @Test func createFirestoreInstance() throws {
        print("[FirestoreInstanceTests] 🧪 Testing Firestore instance creation")

        print("[FirestoreInstanceTests] 📝 Getting first Firestore instance...")
        _ = try Firestore.firestore()
        print("[FirestoreInstanceTests] ✅ First instance created")

        print("[FirestoreInstanceTests] 📝 Getting second Firestore instance (should be cached)...")
        _ = try Firestore.firestore()
        print("[FirestoreInstanceTests] ✅ Second instance obtained")

        print("[FirestoreInstanceTests] 📝 Checking if both instances were created...")
        // Both instances should be successfully created (non-nil by definition)
        // Since firestore() throws on failure, we just verify we got here
        print("[FirestoreInstanceTests] ✅ Both instances created successfully")

        print("[FirestoreInstanceTests] ✅ Test completed successfully")
    }
}
