//
//  CollectionReference+gRPC.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/10.
//

import Foundation

extension CollectionReference {

    public func getDocuments<T: Decodable>(type: T.Type) async throws -> [T] {
        let firestore = try Firestore.firestore()
        return try await getDocuments(type: type, firestore: firestore)
    }

    public func getDocuments() async throws -> QuerySnapshot {
        let firestore = try Firestore.firestore()
        return try await getDocuments(firestore: firestore)
    }
}
