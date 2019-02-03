//
//  User.swift
//  App
//
//  Created by phung on 2/3/19.
//

import Vapor
import FluentPostgreSQL

final class User: Codable {
    var id: Int?
    var name: String
    var username: String
    init(name: String, username: String) {
        self.name = name
        self.username = username
    }
}
extension User: PostgreSQLModel {}
extension User: Content {}
extension User: Migration {}
extension User: Parameter {}
