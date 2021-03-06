/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Vapor
import FluentPostgreSQL // ~~ phai import cai nay
import Fluent // ~~ phai import cai nay
import Authentication

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        
        acronymsRoutes.get(use: getAllHandler)//admin only remove later
        
        //    acronymsRoutes.get(Acronym.parameter, use: getHandler)
        //    acronymsRoutes.get("search", use: searchHandler)
        //    acronymsRoutes.get("first", use: getFirstHandler)
        //    acronymsRoutes.get("sorted", use: sortedHandler)
        //    acronymsRoutes.get(Acronym.parameter, "user", use: getUserHandler)
        
        
        //Lấy hết tất cả category có chứa acronym
        acronymsRoutes.get(Acronym.parameter, "categories", use: getCategoriesHandler)
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = acronymsRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.get("getMyItemList", use: getAllMyItemHandler)//for admin only
        tokenAuthGroup.post(ItemParam.self, at: "addNew", use: createHandler)
        tokenAuthGroup.post(ItemParam.self, at: "editMyItemHandler", use: editMyItemHandler)
        tokenAuthGroup.post(ItemParam.self, at: "deleteMyItemHandler", use: deleteMyItemHandler)
        tokenAuthGroup.get(Acronym.parameter, "user",use: getParentHandler)
        //getAcronymWithUserAndCategories
        tokenAuthGroup.get(Acronym.parameter,"getAcronymWithUserAndCategories",use: getAcronymWithUserAndCategories)
        
        
        
        
        tokenAuthGroup.delete(Acronym.parameter, use: deleteHandler)
        tokenAuthGroup.post(Acronym.parameter, "categories", Category.parameter, use: addCategoriesHandler)
        tokenAuthGroup.delete(Acronym.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
        
        
        
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    func createHandler(_ req: Request, itemParam: ItemParam) throws -> Future<Acronym> {
        let user = try req.requireAuthenticated(User.self)
        
        let acronym = try Acronym(short: itemParam.short ?? "", long: itemParam.long ?? "", userID: user.requireID())
        return acronym.save(on: req)
    }
    //cai nay chi de cho Admin su dung.!
    func getAllMyItemHandler(_ req: Request) throws -> Future<[Acronym]> {
        let user = try req.requireAuthenticated(User.self)
        let id = try user.requireID()
        return Acronym.query(on: req).filter(\.userID == id).all()
    }
    
    
    func editMyItemHandler(_ req: Request,itemParam: ItemParam) throws -> Future<Acronym> {
        let user = try req.requireAuthenticated(User.self)
        let id = try user.requireID()
       //https://github.com/vapor/fluent-sqlite/issues/15
        
        //You can't return an optional from a request handler. You have to unwrap it first:
        
        ///```swift
        ///return Dish.find(id, on: req).unwrap(or: Abort(.notFound))
        ///```
        //Query tìm item có id và có user trùng..-> tìm thấy thì edit. ko tìm thấy thì unwrap abort.

        return Acronym.query(on: req).filter(\.userID == id).filter(\.id == itemParam.id ?? 0).first().unwrap(or: Abort(.notFound)).flatMap(to: Acronym.self) { item in
            item.long = itemParam.long ?? ""
            item.short = itemParam.short ?? ""
            return item.update(on: req)
            
        }
        
    }
    func deleteMyItemHandler(_ req: Request,itemParam: ItemParam) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        let id = try user.requireID()
        //https://github.com/vapor/fluent-sqlite/issues/15
        
        //You can't return an optional from a request handler. You have to unwrap it first:
        
        ///```swift
        ///return Dish.find(id, on: req).unwrap(or: Abort(.notFound))
        ///```
        //Query tìm item có id và có user trùng..-> tìm thấy thì edit. ko tìm thấy thì unwrap abort.
        
        return Acronym.query(on: req).filter(\.userID == id).filter(\.id == itemParam.id ?? 0).first().unwrap(or: Abort(.notFound)).flatMap(to: HTTPStatus.self) { item in
            return item.delete(on: req).transform(to: HTTPStatus.noContent)
            
        }
        
    }
    
    
    
    //code cho biet' vi thuc te' ko the get user cua nguoi kha'c, co the du`ng cho case kha'c quan he cha con!, ko nhat thiet la user-item
    func getParentHandler(_ req: Request) throws -> Future<User> {
        return try req
            .parameters.next(Acronym.self)
            .flatMap(to: User.self) { acronym in
                acronym.user.get(on: req)
        }
    }
    
    func getAcronymWithUserAndCategories(_ req: Request) throws -> Future<AcronymWithUserAndCategories> {
        return try req.parameters.next(Acronym.self)
            .flatMap(to: AcronymWithUserAndCategories.self) { acronym in
                let futureA = acronym.user.get(on: req)
                let futureB = try acronym.categories.query(on: req).all()
                return map(to: AcronymWithUserAndCategories.self, futureA, futureB) { user, categories in
                     return AcronymWithUserAndCategories(acronym: acronym, user: user, categories: categories)
                }

        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
//
//    func updateHandler(_ req: Request) throws -> Future<Acronym> {
//        return try flatMap(to: Acronym.self,
//                           req.parameters.next(Acronym.self),
//                           req.content.decode(ItemParam.self)) { acronym, updateData in
//                            acronym.short = updateData.short ?? ""
//                            acronym.long = updateData.long ?? ""
//                            let user = try req.requireAuthenticated(User.self)
//                            acronym.userID = try user.requireID()
//                            return acronym.save(on: req)
//        }
//    }
//
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Acronym.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
    
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.short ~~ searchTerm)
            or.filter(\.long ~~ searchTerm)
            }.all()
    }
    
    func getFirstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym.query(on: req).first().map(to: Acronym.self) { acronym in
            guard let acronym = acronym else {
                throw Abort(.notFound)
            }
            return acronym
        }
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).sort(\.short, .ascending).all()
    }
    
    func getUserHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(Acronym.self).flatMap(to: User.Public.self) { acronym in
            acronym.user.get(on: req).convertToPublic()
        }
    }
    
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self)) { acronym, category in
            return acronym.categories.attach(category, on: req).transform(to: .created)
        }
    }
    
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Acronym.self).flatMap(to: [Category].self) { acronym in
            try acronym.categories.query(on: req).all()
        }
    }
    
    func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Acronym.self), req.parameters.next(Category.self)) { acronym, category in
            return acronym.categories.detach(category, on: req).transform(to: .noContent)
        }
    }
}
