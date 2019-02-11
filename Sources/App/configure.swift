import FluentPostgreSQL
import Vapor
import Authentication
import Leaf
/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(LeafProvider())
    try services.register(AuthenticationProvider())
    
    
    
    
    
    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a database
    var databases = DatabasesConfig()
    // 3
    let databaseConfig = PostgreSQLDatabaseConfig(
        hostname: "localhost",
        username: "vapor",
        database: "vapor",
        password: "password")
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)
    var migrations = MigrationConfig()
    // 4
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Token.self, database: .psql)

    
    migrations.add(migration: AdminUser.self, database: .psql)
    //them field cho User thi add them, neu run tu dau` thi ko can add, chi add khi chay database real can update!
    //migrations.add(migration: AddTwitterToUser.self,database: .psql)
    //migrations.add(migration: AddCreatedTimeToUser.self,database: .psql)
    
    
    services.register(migrations)
}
