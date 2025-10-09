import Testing
@testable import Firestore

@Suite("Range Query Tests", .disabled("Requires actual Firebase credentials"))
struct RangeQueryTests {

    let path = "test/range/items"

    struct CalendarItem: Codable {
        var startTime: Timestamp
        var endTime: Timestamp
    }

    init() throws {
        try initializeFirebaseForTesting()
    }

    private func setupTestData() async throws {
        let ref = try Firestore.firestore().collection(path)
        let batch = try Firestore.firestore().batch()
        let item0 = CalendarItem(
            startTime: .init(year: 2023, month: 4, day: 12),
            endTime: .init(year: 2023, month: 4, day: 14)
        )
        let item1 = CalendarItem(
            startTime: .init(year: 2023, month: 4, day: 13),
            endTime: .init(year: 2023, month: 4, day: 15)
        )
        let item2 = CalendarItem(
            startTime: .init(year: 2023, month: 4, day: 14),
            endTime: .init(year: 2023, month: 4, day: 16)
        )
        let item3 = CalendarItem(
            startTime: .init(year: 2023, month: 4, day: 15),
            endTime: .init(year: 2023, month: 4, day: 17)
        )
        let item4 = CalendarItem(
            startTime: .init(year: 2023, month: 4, day: 16),
            endTime: .init(year: 2023, month: 4, day: 18)
        )
        try batch.setData(from: item0, forDocument: ref.document("0"))
        try batch.setData(from: item1, forDocument: ref.document("1"))
        try batch.setData(from: item2, forDocument: ref.document("2"))
        try batch.setData(from: item3, forDocument: ref.document("3"))
        try batch.setData(from: item4, forDocument: ref.document("4"))
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
            let snapshot = try await ref
                .where(field: "startTime", isEqualTo: Timestamp(year: 2023, month: 4, day: 12))
                .getDocuments()
            #expect(snapshot.documents.count == 1)
        }
    }

    @Test func whereQueryIsNotEqualTo() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref
                .where(field: "startTime", isNotEqualTo: Timestamp(year: 2023, month: 4, day: 12))
                .getDocuments()
            #expect(snapshot.documents.count == 4)
        }
    }

    @Test func whereQueryIsLessThan() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref
                .where(field: "startTime", isLessThan: Timestamp(year: 2023, month: 4, day: 14))
                .getDocuments()
            #expect(snapshot.documents.count == 2)
        }
    }

    @Test func whereQueryIsLessThanOrEqualTo() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref
                .where(field: "startTime", isLessThanOrEqualTo: Timestamp(year: 2023, month: 4, day: 14))
                .getDocuments()
            #expect(snapshot.documents.count == 3)
        }
    }

    @Test func whereQueryIsGreaterThan() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref
                .where(field: "startTime", isGreaterThan: Timestamp(year: 2023, month: 4, day: 13))
                .getDocuments()
            #expect(snapshot.documents.count == 3)
        }
    }

    @Test func whereQueryIsGreaterThanOrEqualTo() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref
                .where(field: "startTime", isGreaterThanOrEqualTo: Timestamp(year: 2023, month: 4, day: 13))
                .getDocuments()
            #expect(snapshot.documents.count == 4)
        }
    }

    @Test func whereQueryIn() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref
                .where(field: "startTime", in: [Timestamp(year: 2023, month: 4, day: 12), Timestamp(year: 2023, month: 4, day: 13)])
                .getDocuments()
            #expect(snapshot.documents.count == 2)
        }
    }

    @Test func whereQueryNotIn() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref
                .where(field: "startTime", notIn: [Timestamp(year: 2023, month: 4, day: 12), Timestamp(year: 2023, month: 4, day: 13)])
                .getDocuments()
            #expect(snapshot.documents.count == 3)
        }
    }

    @Test func whereQueryAndGreaterThanOrEqualToLessThan() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref
                .and([
                    ("startTime" >= Timestamp(year: 2023, month: 4, day: 12)),
                    ("startTime" < Timestamp(year: 2023, month: 4, day: 14))
                ])
                .getDocuments()
            #expect(snapshot.documents.count == 2)
        }
    }

    @Test func whereQueryAndGreaterThanOrEqualToLessThanOrEqualTo() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref
                .and([
                    ("startTime" >= Timestamp(year: 2023, month: 4, day: 12)),
                    ("startTime" <= Timestamp(year: 2023, month: 4, day: 14))
                ])
                .getDocuments()
            #expect(snapshot.documents.count == 3)
        }
    }

    @Test func whereQueryOrAndGreaterThanOrEqualToLessThan() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref
                .or([
                    .and([
                        ("startTime" >= Timestamp(year: 2023, month: 4, day: 12)),
                        ("startTime" < Timestamp(year: 2023, month: 4, day: 13))
                    ]),
                    .and([
                        ("startTime" >= Timestamp(year: 2023, month: 4, day: 14)),
                        ("startTime" < Timestamp(year: 2023, month: 4, day: 15))
                    ])
                ])
                .getDocuments()
            #expect(snapshot.documents.count == 2)
        }
    }

    @Test func whereQueryOrAndGreaterThanOrEqualToLessThanOrEqualToo() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        do {
            let snapshot = try await ref
                .or([
                    .and([
                        ("startTime" >= Timestamp(year: 2023, month: 4, day: 12)),
                        ("startTime" <= Timestamp(year: 2023, month: 4, day: 13))
                    ]),
                    .and([
                        ("startTime" >= Timestamp(year: 2023, month: 4, day: 14)),
                        ("startTime" <= Timestamp(year: 2023, month: 4, day: 15))
                    ])
                ])
                .getDocuments()
            #expect(snapshot.documents.count == 4)
        }
    }
}
