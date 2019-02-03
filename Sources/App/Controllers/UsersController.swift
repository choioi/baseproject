//
//  UsersController.swift
//  App
//
//  Created by phung on 2/3/19.
//

import Foundation
import Vapor
// 1
struct UsersController: RouteCollection {
    // 2
    func boot(router: Router) throws {
        // 3
        let usersRoute = router.grouped("api", "users")
        // 4
        usersRoute.post(User.self, use: createHandler)
        usersRoute.get(use: getAllHandler)
        
    }
    // 5
    func createHandler(
        _ req: Request,
        user: User
        ) throws -> Future<User> {
        // 6
        return user.save(on: req)
    }
    func getAllHandler(_ req: Request) throws -> Future<[User]> {
        // 2
        return User.query(on: req).all()
    }
    // 3
    func getHandler(_ req: Request) throws -> Future<User> {
        // 4
        return try req.parameters.next(User.self)
    }
}
