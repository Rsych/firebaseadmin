import Testing
@testable import Firestore

@Suite("Where Query Tests")
struct WhereQueryTests {

    let path = "test/where/items"

    init() {
        initializeFirebaseForTesting()
    }

    private func setupTestData() async throws {
        let ref = try Firestore.firestore().collection(path)
        func isEven(_ number: Int) -> Bool {
            return number % 2 == 0
        }
        let batch = try Firestore.firestore().batch()
        (1...10).forEach { index in
            batch.setData(data: [
                "index": index,
                "even": isEven(index)
            ], forDocument: ref.document("\(index)"))
        }
        try await batch.commit()
    }

    private func cleanupTestData() async throws {
        let firestore = try Firestore.firestore()
        let collection = firestore.collection(path)
        let snapshot = try await collection.getDocuments()
        for document in snapshot.documents {
            try await document.documentReference.delete()
        }
    }

    @Test func whereQueryIsEqualTo() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref.getDocuments()
            #expect(snapshot.documents.count == 10)
        }
        do {
            let snapshot = try await ref
                .where(field: "even", isEqualTo: true)
                .getDocuments()
            #expect(snapshot.documents.count == 5)
            snapshot.documents.forEach { document in
                #expect(document.data()!["even"] as! Bool == true)
            }
        }
    }

    @Test func whereQueryIsNotEqualTo() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref.getDocuments()
            #expect(snapshot.documents.count == 10)
        }
        do {
            let snapshot = try await ref
                .where(field: "even", isNotEqualTo: true)
                .getDocuments()
            #expect(snapshot.documents.count == 5)
            snapshot.documents.forEach { document in
                #expect(document.data()!["even"] as! Bool == false)
            }
        }
    }

    @Test func whereQueryIsLessThan() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref.getDocuments()
            #expect(snapshot.documents.count == 10)
        }
        do {
            let snapshot = try await ref
                .where(field: "index", isLessThan: 5)
                .getDocuments()
            #expect(snapshot.documents.count == 4)
            snapshot.documents.forEach { document in
                #expect((document.data()!["index"] as! Int) < 5)
            }
        }
    }

    @Test func whereQueryIsLessThanOrEqualTo() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref.getDocuments()
            #expect(snapshot.documents.count == 10)
        }
        do {
            let snapshot = try await ref
                .where(field: "index", isLessThanOrEqualTo: 5)
                .getDocuments()
            #expect(snapshot.documents.count == 5)
            snapshot.documents.forEach { document in
                #expect((document.data()!["index"] as! Int) <= 5)
            }
        }
    }

    @Test func whereQueryIsGreaterThan() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref.getDocuments()
            #expect(snapshot.documents.count == 10)
        }
        do {
            let snapshot = try await ref
                .where(field: "index", isGreaterThan: 5)
                .getDocuments()
            #expect(snapshot.documents.count == 5)
            snapshot.documents.forEach { document in
                #expect((document.data()!["index"] as! Int) > 5)
            }
        }
    }

    @Test func whereQueryIsGreaterThanOrEqualTo() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref.getDocuments()
            #expect(snapshot.documents.count == 10)
        }
        do {
            let snapshot = try await ref
                .where(field: "index", isGreaterThanOrEqualTo: 5)
                .getDocuments()
            #expect(snapshot.documents.count == 6)
            snapshot.documents.forEach { document in
                #expect((document.data()!["index"] as! Int) >= 5)
            }
        }
    }

    @Test func whereQueryIn() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref.getDocuments()
            #expect(snapshot.documents.count == 10)
        }
        do {
            let snapshot = try await ref
                .where(field: "index", in: [1, 3, 5, 7, 9])
                .getDocuments()
            #expect(snapshot.documents.count == 5)
            snapshot.documents.forEach { document in
                #expect(document.data()!["even"] as! Bool == false)
            }
        }
    }

    @Test func whereQueryNotIn() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref.getDocuments()
            #expect(snapshot.documents.count == 10)
        }
        do {
            let snapshot = try await ref
                .where(field: "index", notIn: [1, 3, 5, 7, 9])
                .getDocuments()
            #expect(snapshot.documents.count == 5)
            snapshot.documents.forEach { document in
                #expect(document.data()!["even"] as! Bool == true)
            }
        }
    }
}
