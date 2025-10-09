//
//  TransactionTests.swift
//
//
//  Created by Norikazu Muramoto on 2023/05/13.
//

import Testing
@testable import Firestore

@Suite("Transaction Tests")
struct TransactionTests {

    init() {
        initializeFirebaseForTesting()
    }

    @Test func increment() async throws {
        let firestore = try Firestore.firestore()
        let ref = firestore.collection("test").document("transaction")
        try await ref.delete()

        func increments() async {
            await withTaskGroup(of: Void.self) { group in
                for _ in (0..<10) {
                    group.addTask {
                        try! await firestore.runTransaction { transaction in
                            let snapshot = try await transaction.get(documentReference: ref)
                            if snapshot.exists {
                                let count = snapshot.data()!["count"] as! Int
                                transaction.set(documentReference: ref, data: ["count": count + 1])
                            } else {
                                transaction.create(documentReference: ref, data: ["count": 0])
                            }
                        }
                    }
                }
            }
        }

        await increments()
        let snapshot = try await ref.getDocument()
        let documentData = snapshot.data()!
        #expect(documentData["count"] as! Int == 9)
    }

    @Test func multiIncrement() async throws {
        let firestore = try Firestore.firestore()
        let ref0 = firestore.collection("test").document("transaction0")
        let ref1 = firestore.collection("test").document("transaction1")
        try await ref0.delete()
        try await ref1.delete()

        func increments() async {
            await withTaskGroup(of: Void.self) { group in
                for _ in (0..<10) {
                    group.addTask {
                        try! await firestore.runTransaction { transaction in
                            let snapshot0 = try await transaction.get(documentReference: ref0)
                            let snapshot1 = try await transaction.get(documentReference: ref1)
                            if snapshot0.exists {
                                let count = snapshot0.data()!["count"] as! Int
                                transaction.set(documentReference: ref0, data: ["count": count + 1])
                            } else {
                                transaction.create(documentReference: ref0, data: ["count": 0])
                            }
                            if snapshot1.exists {
                                let count = snapshot1.data()!["count"] as! Int
                                transaction.set(documentReference: ref1, data: ["count": count + 1])
                            } else {
                                transaction.create(documentReference: ref1, data: ["count": 0])
                            }
                        }
                    }
                }
            }
        }

        await increments()
        let snapshot0 = try await ref0.getDocument()
        let snapshot1 = try await ref1.getDocument()
        #expect(snapshot0.data()!["count"] as! Int == 9)
        #expect(snapshot1.data()!["count"] as! Int == 9)
    }
}
