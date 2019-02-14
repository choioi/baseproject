//
//  19-02-13-MakeCategoriesUnique.swift
//  App
//
//  Created by phung on 2/13/19.
//

import Foundation
import FluentPostgreSQL
import Vapor

// 1
struct MakeCategoriesUnique: Migration {
    // 2
    typealias Database = PostgreSQLDatabase
    // 3
    static func prepare(
        on connection: PostgreSQLConnection) -> Future<Void> {
        // 4
        return Database.update(
            Category.self, on: connection
        ) { builder in
            // 5 name la duy nhat ko dc trung
            builder.unique(on: \.name)

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
            builder.deleteUnique(from: \.name)

        }
    }
}
