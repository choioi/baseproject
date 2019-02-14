//
//  LoginParam.swift
//  App
//
//  Created by phung on 2/9/19.
//
import Vapor
import FluentPostgreSQL
final class TokenParam: Codable {
    var token: String
    
}
extension TokenParam: Content {}


struct ItemParam: Content {
    let id: Int?
    let short: String?
    let long: String?
}

struct AcronymResponse: Content {
    let data: Acronym?
    let error: Bool?
    let reason:String?
    init(data: Acronym? = nil,error:Bool = false, reason: String? = nil) {
        self.data = data
        self.error = error
        self.reason = reason
    }
}
