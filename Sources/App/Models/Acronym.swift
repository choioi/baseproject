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
import FluentPostgreSQL

final class Acronym: Codable {
  var id: Int?
  var short: String
  var long: String
  var userID: User.ID

  init(short: String, long: String, userID: User.ID) {
    self.short = short
    self.long = long
    self.userID = userID
  }
}

extension Acronym: PostgreSQLModel {}
extension Acronym: Content {}
extension Acronym: Parameter {}

extension Acronym {
  var user: Parent<Acronym, User> {
    return parent(\.userID)
  }

  var categories: Siblings<Acronym, Category, AcronymCategoryPivot> {
    return siblings()
  }
}

extension Acronym: Migration {
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.reference(from: \.userID, to: \User.id)
    }
  }
}

//AcronymWithUserAndCategories for purpose show only

final class AcronymWithUserAndCategories: Codable {
    var acronym: Acronym
    var user: User
    var categories: [Category]
    init(acronym: Acronym, user: User, categories: [Category]) {
        self.acronym = acronym
        self.user = user
        self.categories = categories
    }
}
extension AcronymWithUserAndCategories: Content {}
