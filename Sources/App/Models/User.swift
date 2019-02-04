//
//  User.swift
//  App
//
//  Created by phung on 2/3/19.
//

import Vapor
import FluentPostgreSQL
import Authentication


final class User: Codable {
    var id: Int?
    var name: String
    var email: String
    var password: String
    init(name: String, email: String,password: String) {
        self.name = name
        self.email = email
        self.password = password
    }
    final class Public: Codable {
        var id: Int?
        var name: String
        var email: String
        
        init(id: Int?, name: String, email: String) {
            self.id = id
            self.name = name
            self.email = email
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
                builder.unique(on: \.email)
            }
    }
}
//2 ham nay di chung! Future 1 function
extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, email: email)
    }
}
extension Future where T: User {
    func convertToPublic() -> Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.convertToPublic()
        }
    }
}
extension User: BasicAuthenticatable {
    static let usernameKey: UsernameKey = \User.email
    static let passwordKey: PasswordKey = \User.password
    

}
