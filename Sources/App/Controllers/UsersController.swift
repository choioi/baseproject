import Foundation
import Vapor
import Crypto
import Authentication


struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
       //BAsic authen
//        let basicAuthMiddleware = User(name: "demo", username: "demo", password: "123").basicAuthMiddleware(using: BCryptDigest())
        
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)

        let protected = usersRoute.grouped(
            basicAuthMiddleware,
            guardAuthMiddleware)
        
        usersRoute.post("register", use: register)
        usersRoute.post(User.self, use: createHandler)
        protected.post("login", use: login)
        protected.get(use: getAllHandler)
        protected.get(User.parameter, use: getHandler)
        protected.delete(User.parameter, use: deleteHandler)
        protected.put(User.parameter, use: updateHandler)

        
    }
    //ADD
    func createHandler(_ req: Request, user: User) throws -> Future<User.Public> {
        user.password = try BCrypt.hash(user.password)
        return user.save(on: req).convertToPublic()
    }
    func register(_ req: Request) throws -> Future<User.Public> {
        return try req.content.decode(User.self).flatMap { user in
            let hasher = try req.make(BCryptDigest.self)
            let passwordHashed = try hasher.hash(user.password)
            let newUser = User(name: user.name, email: user.email, password: passwordHashed)
            return newUser.save(on: req).map { storedUser in
                return storedUser.convertToPublic()
            }
        }
    }
    
    func login(req : Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req)
    }
    
    //LIST ALL
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        
        //return User.query(on: req).all() // Auto Decode User
        return User.query(on: req).decode(data: User.Public.self).all()
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
                            user.password = try BCrypt.hash(updatedUser.password)
                            user.email = updatedUser.email
                            user.name = updatedUser.name
                            return user.save(on: req)
        }
    }
    
}

