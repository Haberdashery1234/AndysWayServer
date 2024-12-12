import FluentPostgresDriver
import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdCompression
import HummingbirdFluent

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable.
/// Any variables added here also have to be added to `App` in App.swift and
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var migrate: Bool { get }
    var hostname: String { get }
    var port: Int { get }
}

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger =  {
        var logger = Logger(label: "andys-way-server")
        logger.logLevel = .debug
        return logger
    }()

    let fluent = Fluent(logger: logger)
    fluent.databases.use(
        .postgres(
            configuration: .init(
                hostname: environment.get("POSTGRES_HOST") ?? "localhost",
                username: environment.get("POSTGRES_USER") ?? "markers",
                password: environment.get("POSTGRES_PASSWORD") ?? "",
                database: environment.get("POSTGRES_DB") ?? "markers",
                tls: .disable
            )
        ),
        as: .psql
    )

    await fluent.migrations.add(CreateUser())
    await fluent.migrations.add(CreateMarker())

    logger.info("Am I migrating?")
    // if arguments.migrate {
        logger.info("Migrating")
        try await fluent.migrate()
    // }

    let userRepository = UserRepository(fluent: fluent)

    let router = Router(context: AppRequestContext.self)

    router.addMiddleware {
        LogRequestsMiddleware(.info)
        ResponseCompressionMiddleware(minimumResponseSizeToCompress: 256)
        FileMiddleware(logger: logger)
        CORSMiddleware(
            allowOrigin: .originBased,
            allowHeaders: [.contentType],
            allowMethods: [.get, .options, .post, .delete, .patch]
        )
    }

    // Add health endpoint
    router.get("/health") { _, _ -> HTTPResponse.Status in
        return .ok
    }

    let sessionAuthenticator = SessionAuthenticator(users: userRepository, context: AppRequestContext.self)
    MarkerController(fluent: fluent, sessionAuthenticator: sessionAuthenticator).addRoutes(to: router.group("api/markers"))
    UserController(fluent: fluent, sessionAuthenticator: sessionAuthenticator).addRoutes(to: router.group("api/users"))

    let app = Application(
        router: router,
        configuration: .init(address: .hostname(arguments.hostname, port: arguments.port))
    )
    return app
}