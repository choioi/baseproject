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
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
       
        let guardAuthMiddleware = User.guardAuthMiddleware()
       
        let tokenProtected = usersRoute.grouped(
            tokenAuthMiddleware,
            guardAuthMiddleware)
        
        let basicProtected = usersRoute.grouped(
            basicAuthMiddleware,
            guardAuthMiddleware)
        
        //usersRoute.post("register",User.self,use: createHandler2)// thua`n data!
        basicProtected.post(User.self, at: "register", use: createHandler3)//Nen dung cai na`y... tich hoo san content ko can decode cac kieu~
        basicProtected.post(User.self, use: createHandler)
        basicProtected.post("login", use: login)
        
        
        tokenProtected.get(use: getAllHandler)
        tokenProtected.get(User.parameter, use: getHandler)
        tokenProtected.delete(User.parameter, use: deleteHandler)
        tokenProtected.put(User.parameter, use: updateHandler)
        tokenProtected.post(Token.self, at: "profile", use: profile)
        tokenProtected.post("update", use: updateHandler2)

        
    }
    //=================================ADD=================================
    func createHandler(_ req: Request, user: User) throws -> Future<User.Public> {
        user.password = try BCrypt.hash(user.password)
        return user.save(on: req).convertToPublic()
    }
    func createHandler2(_ req: Request) throws -> Future<User.Public> {
        return try req.content.decode(User.self).flatMap { user in
            let hasher = try req.make(BCryptDigest.self)
            let passwordHashed = try hasher.hash(user.password)
            let newUser = User(name: user.name, email: user.email, password: passwordHashed)
            return newUser.save(on: req).map { storedUser in
                return storedUser.convertToPublic()
            }
        }
    }
    func createHandler3(_ req: Request,user: User) throws -> Future<User.Public> {
        user.password = try BCrypt.hash(user.password)//update raw password thanh hashed password
        return user.save(on: req).convertToPublic() // save xong vao database return model public!
    }
    //=================================ADD=================================
   
    //EDIT
    func updateHandler(_ req: Request) throws -> Future<User> {
        return try flatMap(to: User.self,
                           req.parameters.next(User.self),
                           req.content.decode(User.self)) { user, updatedUser in
                            
                            //authen
                            let user = try req.requireAuthenticated(User.self)

                            user.password = try BCrypt.hash(updatedUser.password)
                            user.email = updatedUser.email
                            user.name = updatedUser.name
                            
                            return user.save(on: req)
        }
    }
    func updateHandler2(_ req: Request) throws -> Future<User> {
        //Decode thi cần time -> ko có ngay-> kiểu Future.
        let postUserModel = try req.content.decode(User.self)

        return postUserModel
    }
    
    
    
    //=================================LOGIN=================================
    func login(req : Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self)
        //let user = try req.
        let token = try Token.generate(for: user)
        return token.save(on: req)
    }
    func login2(_ req: Request) throws -> User.Public {
        let user = try req.requireAuthenticated(User.self)
        return User.Public(id: try user.requireID(), name: user.name, email: user.email)
    }
    //=================================LOGIN=================================
    
    //=================================VIEW PROFILE=================================
    func profile(_ req: Request,token: Token) throws -> String {
        //let tokenID = token.
        let user = try req.requireAuthenticated(User.self)
        return "You're viewing \(user.email) profile."
        
    }
    
    //=================================VIEW PROFILE=================================
    
    
    
    
    
    
    //LIST ALL
    func getAllHandler(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    
//    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
//        return User.query(on: req).decode(data: User.Public.self).all()
//    }
//
    //LIST ONE
    func getHandler(_ req: Request) throws -> Future<User.Public> {
       
        return try req.parameters.next(User.self).convertToPublic()
    }
    //DELETE
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(User.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
    
    
}

