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

    // register custom service types
    services.register(LogMiddleware.self)
    services.register(SecretMiddleware.self)
    
    // configure middleware
    var middleware = MiddlewareConfig()
    middleware.use(LogMiddleware.self)
    middleware.use(ErrorMiddleware.self)
    services.register(middleware)

    // Configure a database
    var databases = DatabasesConfig()
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "vapor"
    let databaseName = Environment.get("DATABASE_DB") ?? "vapor"
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    
    let databaseConfig: PostgreSQLDatabaseConfig
    if let url = Environment.get("DATABASE_URL") {
        databaseConfig = PostgreSQLDatabaseConfig(url: url)!
    } else {
        let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
        let username = Environment.get("DATABASE_USER") ?? "vapor"
        let databaseName = Environment.get("DATABASE_DB") ?? "vapor"
        let databasePort = 5432
        let password = Environment.get("DATABASE_PASSWORD") ?? "password"
        
        databaseConfig = PostgreSQLDatabaseConfig(
            hostname: hostname,
            port: databasePort,
            username: username,
            database: databaseName,
            password: password)
    }
    
    
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    services.register(databases)
    
    
    var migrations = MigrationConfig()
    // 4
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Token.self, database: .psql)
    migrations.add(model: Acronym.self, database: .psql)
    migrations.add(model: Category.self, database: .psql)
    migrations.add(model: AcronymCategoryPivot.self, database: .psql)
    
    migrations.add(migration: AdminUser.self, database: .psql)
//    switch env {
//    case .development, .testing:
//        migrations.add(migration: AdminUser.self, database: .psql)
//    default:
//        break
//    }
    
    migrations.add(
        migration: MakeCategoriesUnique.self,
        database: .psql)
    //them field cho User thi add them, neu run tu dau` thi ko can add, chi add khi chay database real can update!
    //migrations.add(migration: AddTwitterToUser.self,database: .psql)
    //migrations.add(migration: AddCreatedTimeToUser.self,database: .psql)
    //migrations.add(migration: AddCreatedTimeToToken.self,database: .psql)
    services.register(migrations)
}
