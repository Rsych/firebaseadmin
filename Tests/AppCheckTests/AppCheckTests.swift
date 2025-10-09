//
//  AppCheckTests.swift
//
//
//  Created by Norikazu Muramoto on 2023/05/12.
//

import Testing
import AsyncHTTPClient
import NIO
import NIOFoundationCompat
@testable import AppCheck

@Suite("AppCheck Tests")
struct AppCheckTests {

    @Test func appCheck() async throws {
        let token = ""
        let appCheck = AppCheck()
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))
//        try await appCheck.validate(token: "", client: client)

        try await client.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }
}
