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
    var password: String
    init(name: String, username: String,password: String) {
        self.name = name
        self.username = username
        self.password = password
    }
    final class Public: Codable {
        var id: Int?
        var name: String
        var username: String
        
        init(id: Int?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
   
}
extension User: PostgreSQLModel {}
extension User: Content {}
extension User: Parameter {}
extension User.Public: Content {}
//Making usernames unique
extension User: Migration {
    static func prepare(on connection: PostgreSQLConnection)
        -> Future<Void> {
            return Database.create(self, on: connection) { builder in
                try addProperties(to: builder)
                builder.unique(on: \.username)
            }
    }
}
//2 ham nay di chung! Future 1 function
extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}
extension Future where T: User {
    func convertToPublic() -> Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.convertToPublic()
        }
    }
}
