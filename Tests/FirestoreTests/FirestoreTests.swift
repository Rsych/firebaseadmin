import Testing
@testable import Firestore

@Suite("Firestore Tests")
struct FirestoreTests {

    init() {
        initializeFirebaseForTesting()
    }

    @Test func path() async throws {
        #expect(try Firestore.firestore().collection("test").document("0").path == "test/0")
        #expect(try Firestore.firestore().collection("test").document("0").path == "test/0")
        #expect(try Firestore.firestore().collection("test").document("0/test/0").path == "test/0/test/0")
        #expect(try Firestore.firestore().document("/test/0").path == "test/0")
        #expect(try Firestore.firestore().document("/test/0").collection("test").path == "test/0/test")
        #expect(try Firestore.firestore().document("/test/0").collection("test").document("0").path == "test/0/test/0")
        #expect(try Firestore.firestore().document("/test/0").parent.path == "test")
        #expect(try Firestore.firestore().document("/test/0").parent.path == "test")
    }
}
