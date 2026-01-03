import Testing
@testable import Firestore

@Suite("Range Query Tests")
struct RangeQueryTests {

    let path = "test/range/items"

    struct CalendarItem: Codable {
        var startTime: Timestamp
        var endTime: Timestamp
    }

    init() {
        initializeFirebaseForTesting()
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

    @Test func orderByAscending() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        let snapshot = try await ref
            .order(by: "startTime", descending: false)
            .getDocuments()

        #expect(snapshot.documents.count == 5)

        // Verify ascending order
        let timestamps = snapshot.documents.compactMap { doc -> Timestamp? in
            doc.data()?["startTime"] as? Timestamp
        }

        for i in 0..<(timestamps.count - 1) {
            #expect(timestamps[i].seconds <= timestamps[i + 1].seconds)
        }
    }

    @Test func orderByDescending() async throws {
        try await setupTestData()
        defer { Task { try? await cleanupTestData() } }

        let ref = try Firestore.firestore().collection(path)
        let snapshot = try await ref
            .order(by: "startTime", descending: true)
            .getDocuments()

        #expect(snapshot.documents.count == 5)

        // Verify descending order
        let timestamps = snapshot.documents.compactMap { doc -> Timestamp? in
            doc.data()?["startTime"] as? Timestamp
        }

        for i in 0..<(timestamps.count - 1) {
            #expect(timestamps[i].seconds >= timestamps[i + 1].seconds)
        }
    }

    @Test func offset() async throws {
        try await setupTestData()

        do {
            let ref = try Firestore.firestore().collection(path)
            let snapshot = try await ref
                .order(by: "startTime", descending: false)
                .offset(2)
                .getDocuments()

            // Should skip first 2 documents, returning 3
            #expect(snapshot.documents.count == 3)

            // First result should be item2 (April 14)
            if let firstTimestamp = snapshot.documents.first?.data()?["startTime"] as? Timestamp {
                #expect(firstTimestamp == Timestamp(year: 2023, month: 4, day: 14))
            }
        }

        try await cleanupTestData()
    }

    @Test func offsetWithLimit() async throws {
        try await setupTestData()

        do {
            let ref = try Firestore.firestore().collection(path)
            let snapshot = try await ref
                .order(by: "startTime", descending: false)
                .offset(1)
                .limit(to: 2)
                .getDocuments()

            // Should skip first document, then return 2
            #expect(snapshot.documents.count == 2)

            // Results should be item1 (April 13) and item2 (April 14)
            let timestamps = snapshot.documents.compactMap { doc -> Timestamp? in
                doc.data()?["startTime"] as? Timestamp
            }
            #expect(timestamps.count == 2)
            #expect(timestamps[0] == Timestamp(year: 2023, month: 4, day: 13))
            #expect(timestamps[1] == Timestamp(year: 2023, month: 4, day: 14))
        }

        try await cleanupTestData()
    }

    @Test func startAt() async throws {
        try await setupTestData()

        do {
            let ref = try Firestore.firestore().collection(path)
            let snapshot = try await ref
                .order(by: "startTime", descending: false)
                .start(at: Timestamp(year: 2023, month: 4, day: 14))
                .getDocuments()

            // Should return items starting at April 14 (inclusive)
            #expect(snapshot.documents.count == 3)

            // First result should be item2 (April 14)
            if let firstTimestamp = snapshot.documents.first?.data()?["startTime"] as? Timestamp {
                #expect(firstTimestamp == Timestamp(year: 2023, month: 4, day: 14))
            }
        }

        try await cleanupTestData()
    }

    @Test func startAfter() async throws {
        try await setupTestData()

        do {
            let ref = try Firestore.firestore().collection(path)
            let snapshot = try await ref
                .order(by: "startTime", descending: false)
                .start(after: Timestamp(year: 2023, month: 4, day: 14))
                .getDocuments()

            // Should return items after April 14 (exclusive)
            #expect(snapshot.documents.count == 2)

            // First result should be item3 (April 15)
            if let firstTimestamp = snapshot.documents.first?.data()?["startTime"] as? Timestamp {
                #expect(firstTimestamp == Timestamp(year: 2023, month: 4, day: 15))
            }
        }

        try await cleanupTestData()
    }

    @Test func endAt() async throws {
        try await setupTestData()

        do {
            let ref = try Firestore.firestore().collection(path)
            let snapshot = try await ref
                .order(by: "startTime", descending: false)
                .end(at: Timestamp(year: 2023, month: 4, day: 14))
                .getDocuments()

            // Should return items up to and including April 14
            #expect(snapshot.documents.count == 3)

            // Last result should be item2 (April 14)
            if let lastTimestamp = snapshot.documents.last?.data()?["startTime"] as? Timestamp {
                #expect(lastTimestamp == Timestamp(year: 2023, month: 4, day: 14))
            }
        }

        try await cleanupTestData()
    }

    @Test func endBefore() async throws {
        try await setupTestData()

        do {
            let ref = try Firestore.firestore().collection(path)
            let snapshot = try await ref
                .order(by: "startTime", descending: false)
                .end(before: Timestamp(year: 2023, month: 4, day: 14))
                .getDocuments()

            // Should return items before April 14 (exclusive)
            #expect(snapshot.documents.count == 2)

            // Last result should be item1 (April 13)
            if let lastTimestamp = snapshot.documents.last?.data()?["startTime"] as? Timestamp {
                #expect(lastTimestamp == Timestamp(year: 2023, month: 4, day: 13))
            }
        }

        try await cleanupTestData()
    }

    @Test func startAtEndAt() async throws {
        try await setupTestData()

        do {
            let ref = try Firestore.firestore().collection(path)
            let snapshot = try await ref
                .order(by: "startTime", descending: false)
                .start(at: Timestamp(year: 2023, month: 4, day: 13))
                .end(at: Timestamp(year: 2023, month: 4, day: 15))
                .getDocuments()

            // Should return items from April 13 to April 15 (inclusive on both ends)
            #expect(snapshot.documents.count == 3)

            let timestamps = snapshot.documents.compactMap { doc -> Timestamp? in
                doc.data()?["startTime"] as? Timestamp
            }
            #expect(timestamps.count == 3)
            #expect(timestamps[0] == Timestamp(year: 2023, month: 4, day: 13))
            #expect(timestamps[1] == Timestamp(year: 2023, month: 4, day: 14))
            #expect(timestamps[2] == Timestamp(year: 2023, month: 4, day: 15))
        }

        try await cleanupTestData()
    }

    @Test func startAfterEndBefore() async throws {
        try await setupTestData()

        do {
            let ref = try Firestore.firestore().collection(path)
            let snapshot = try await ref
                .order(by: "startTime", descending: false)
                .start(after: Timestamp(year: 2023, month: 4, day: 12))
                .end(before: Timestamp(year: 2023, month: 4, day: 16))
                .getDocuments()

            // Should return items after April 12 and before April 16 (exclusive on both ends)
            #expect(snapshot.documents.count == 3)

            let timestamps = snapshot.documents.compactMap { doc -> Timestamp? in
                doc.data()?["startTime"] as? Timestamp
            }
            #expect(timestamps.count == 3)
            #expect(timestamps[0] == Timestamp(year: 2023, month: 4, day: 13))
            #expect(timestamps[1] == Timestamp(year: 2023, month: 4, day: 14))
            #expect(timestamps[2] == Timestamp(year: 2023, month: 4, day: 15))
        }

        try await cleanupTestData()
    }
}
