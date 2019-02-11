//
//  19-01-11-AddCreateTimeToUser.swift
//  App
//
//  Created by phung on 2/11/19.
//

import Foundation
import FluentPostgreSQL
import Vapor

// 1
struct AddTwitterToUser: Migration {
    // 2
    typealias Database = PostgreSQLDatabase
    // 3
    static func prepare(
        on connection: PostgreSQLConnection) -> Future<Void> {
        // 4
        return Database.update(
            User.self, on: connection
        ) { builder in
            // 5 them vao 1 field moi
            builder.field(for: \.twitterURL)
            //builder.deleteField(for: \.twitterURL)
        }
    }
    // 6
    static func revert(
        on connection: PostgreSQLConnection
        ) -> Future<Void> {
        // 7
        return Database.update(
            User.self, on: connection
        ) { builder in
            // 8 Neu failt thi xoa field moi do'
            builder.deleteField(for: \.twitterURL)
            //builder.field(for: \.twitterURL)
        }
    }
}
