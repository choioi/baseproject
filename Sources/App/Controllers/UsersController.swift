import Foundation
import Vapor
import Crypto
import Authentication
import FluentPostgreSQL
import Fluent // ~~ phai import cai nay
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
        
        
        //unprotect
        
        usersRoute.get("tokenList", use: getAllTkenHandler)
        
        
        //basic protect
        basicProtected.post(User.self, at: "register", use: createHandler3)//Nen dung cai na`y... tich hoo san content ko can decode cac kieu~
        basicProtected.post(User.self, use: createHandler)
        //basicProtected.post(LoginParam.self, at: "login", use: login)
        basicProtected.get("login", use: login)
        basicProtected.post(TokenParam.self, at: "profile", use: profile)
        
        
        //token protect
        tokenProtected.get(use: getAllHandler)
        tokenProtected.get(User.parameter, use: getHandler)
        tokenProtected.delete(User.parameter, use: deleteHandler)
        tokenProtected.put(User.parameter, use: updateHandler)

        tokenProtected.post(User.self, at: "update", use: updateHandler2)

        
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
            //let newUser = User(name: user.name, email: user.email, password: passwordHashed)
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
    //Ko nen dung cach nay, vi co the hack truyen 1 tham so kha'c
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
    func updateHandler2(_ req: Request,user: User) throws -> Future<User> {
        //Decode thi cần time -> ko có ngay-> kiểu Future.
        let userNeedEdit = try req.requireAuthenticated(User.self) //authen check token, from token return user! qua tuyet voi`!!
        
        userNeedEdit.name = user.name
        //userNeedEdit.email = user.email
        userNeedEdit.password = try BCrypt.hash(user.password)
        //print(user.id)
        
        return userNeedEdit.save(on: req)
        
    }
    
    
    
    //=================================LOGIN=================================
    func login(req : Request) throws -> Future<Token> {
        //clearAllToken(req: req)
        let user = try req.requireAuthenticated(User.self)//check login bang basic authen.
        return clearOldTokenHaveID(req: req, userID: user.id).flatMap { (status) -> (EventLoopFuture<Token>) in
            let token = try Token.generate(for: user)
            return (token.save(on: req))
        }

    }
    func clearAllToken(req : Request) {
        _ = Token.query(on: req).delete(force: true)
    }
    func clearOldTokenHaveID(req : Request,userID: Int?) -> Future<HTTPStatus> {
        return Token.query(on: req).filter(\.userID == userID ?? 0).delete().transform(to: HTTPStatus.continue)
    }
//    func login2(_ req: Request) throws -> User.Public {
//        let user = try req.requireAuthenticated(User.self)
//        return User.Public(id: try user.requireID(), name: user.name, email: user.email)
//    }
    //=================================LOGIN=================================
    
    //=================================VIEW PROFILE=================================
    func profile(_ req: Request,tokenParam: TokenParam) throws -> User {
        let user = try req.requireAuthenticated(User.self)
        return user
    }
    
    
    
    func getToKenFromTokenString(req: Request,tokenString: String) -> Future<Token> {
        print("getToKenFromTokenString")
        return Token.query(on: req).filter(\.token == tokenString).first().unwrap(or: Abort(.notFound))
    }
    func getUserFromUserID(req: Request,userID: Int) -> Future<User> {
        print("getUserFromUserID")
        return User.find(userID, on: req).unwrap(or: Abort(.notFound))
    }
    func getTokenFromUserID(req: Request,userID: Int) -> Future<Token> {
        print("getTokenFromUserID:\(userID)")
        return Token.query(on: req).filter(\.userID == userID).first().unwrap(or: Abort(.notFound))
    }
    
    //=================================VIEW PROFILE=================================
    
    
    
    
    
    
    //LIST ALL USER
    func getAllHandler(_ req: Request) throws -> Future<[User]> {
        return User.query(on: req).all()
    }
    //LIST ALL TOKEN
    func getAllTkenHandler(_ req: Request) throws -> Future<[Token]> {
        return Token.query(on: req).all()
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

