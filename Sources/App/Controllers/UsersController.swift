import Foundation
import Vapor
import Crypto

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        usersRoute.post(User.self, use: createHandler)
        usersRoute.get(User.parameter, use: getHandler)
        usersRoute.delete(User.parameter, use: deleteHandler)
        usersRoute.put(User.parameter, use: updateHandler)
    }
    //ADD
    func createHandler(_ req: Request, user: User) throws -> Future<User.Public> {
        user.password = try BCrypt.hash(user.password)
        return user.save(on: req).convertToPublic()
    }
    //LIST ALL
    func getAllHandler(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    //LIST ONE
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).convertToPublic()
    }
    //DELETE
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(User.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
    //EDIT
    func updateHandler(_ req: Request) throws -> Future<User> {
        return try flatMap(to: User.self,
                           req.parameters.next(User.self),
                           req.content.decode(User.self)) { user, updatedUser in
                            user.password = updatedUser.password
                            return user.save(on: req)
        }
    }
    
}

