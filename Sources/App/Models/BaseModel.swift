//
//  BaseModel.swift
//  App
//
//  Created by phung on 2/9/19.
//
//
//import Vapor
//import FluentPostgreSQL
//import Authentication
//
//class BaseModel: Codable {
//    var error :  Bool? = nil
//    var reason : String? = nil
//    init(error:Bool? = false,reason:String? = nil) {
//        self.error = error
//        self.reason = reason
//    }
//}
//
//
//
/*
class A {
    var b: Bool? = nil
    init(aBool: Bool? = false) {
        self.b = aBool
    }
}

class B: A {
    var s: String? = nil
    convenience init(aString: String) {
        self.init(aBool: false)
        self.s = aString
    }
}

let obj1 = A(aBool: true) // obj1 is now an A, obviously.
let obj2 = B(aBool: true) // obj2 is now a B
*/
