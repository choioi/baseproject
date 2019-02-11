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

