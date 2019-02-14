//
//  19-01-14-AddCreatedTimeToToken.swift
//  App
//
//  Created by phung on 2/13/19.
//
import Foundation

import FluentPostgreSQL
import Vapor

// 1
struct AddCreatedTimeToToken: Migration {
    // 2
    typealias Database = PostgreSQLDatabase
    // 3
    static func prepare(
        on connection: PostgreSQLConnection) -> Future<Void> {
        // 4
        return Database.update(
            Token.self, on: connection
        ) { builder in
            // 5 them vao 2 field moi'!
            builder.field(for: \.createdAt)
            builder.field(for: \.updatedAt)
        }
    }
    // 6: neu chay fail thi` xoa 2 field moi them vao!
    static func revert(
        on connection: PostgreSQLConnection
        ) -> Future<Void> {
        // 7
        return Database.update(
            Token.self, on: connection
        ) { builder in
            // 8
            builder.deleteField(for: \.createdAt)
            builder.deleteField(for: \.updatedAt)
        }
    }
}
