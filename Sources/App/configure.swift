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
    
    
    let databaseConfig: PostgreSQLDatabaseConfig
    
    if let url = Environment.get("DATABASE_URL") {
        databaseConfig = PostgreSQLDatabaseConfig(url: url)!
    } else {
        //check LIVE
        let LIVE:String = Environment.get("DATABASE_LIVE") ?? "false"
        var hostname = "localhost"
        var username = "vapor"
        var databaseName = "vapor"
        var databasePort = 5432
        var password = "password"
        
        if LIVE.lowercased() == "TRUE".lowercased() {
            hostname = Environment.get("DATABASE_HOSTNAME") ?? hostname
            username = Environment.get("DATABASE_USER") ?? username
            databaseName = Environment.get("DATABASE_DB") ?? databaseName
            password = Environment.get("DATABASE_PASSWORD") ?? password
        } else {
            hostname = Environment.get("DATABASE_HOSTNAME_DEV") ?? hostname
            username = Environment.get("DATABASE_USER_DEV") ?? username
            databaseName = Environment.get("DATABASE_DB_DEV") ?? databaseName
            password = Environment.get("DATABASE_PASSWORD_DEV") ?? password
        }

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
