import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works! 422 lan 2"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    let acronymsController = AcronymsController()
    try router.register(collection: acronymsController)
    
    let usersController = UsersController()
    try router.register(collection: usersController)
    
    let categoriesController = CategoriesController()
    try router.register(collection: categoriesController)
  
}
