import Foundation
import Hummingbird
import Logging
import PostgresNIO

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable.
/// Any variables added here also have to be added to `App` in App.swift and
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
    var inMemoryTesting: Bool { get }
}

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "andys-way-server")
        logger.logLevel =
            arguments.logLevel ??
            environment.get("LOG_LEVEL").map { Logger.Level(rawValue: $0) ?? .info } ??
            .info
        return logger
    }()

    let operatingSystem: String
    #if os(Linux)
    operatingSystem = "Linux"
    #else
    operatingSystem = "macOS"
    #endif

    let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
    logger.info("Starting application - \(operatingSystem) \(osVersion)")

    var postgresRepository: MarkerPostgresRepository?
    let router: Router<AppRequestContext>
    if !arguments.inMemoryTesting {
        let config = PostgresClient.Configuration(
                host: environment.get("POSTGRES_HOST") ?? "localhost",
                username: environment.get("POSTGRES_USER") ?? "markers",
                password: environment.get("POSTGRES_PASSWORD") ?? "",
                database: environment.get("POSTGRES_DB") ?? "markers",
                tls: .disable
            )
        let client = PostgresClient(
            configuration: config,
            backgroundLogger: logger
        )
        let repository = MarkerPostgresRepository(client: client, logger: logger)
        postgresRepository = repository
        router = buildRouter(repository)
    } else {
        router = buildRouter(MarkerMemoryRepository())
    }
    var app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "andys-way-server"
        ),
        logger: logger
    )
    // if we setup a postgres service then add as a service and run createTable before
    // server starts
    if let postgresRepository {
        app.addServices(postgresRepository.client)
        app.beforeServerStarts {
            try await postgresRepository.createTable()
        }
    }
    return app
}

/// Build router
func buildRouter(_ repository: some MarkerRepository) -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
    }
    // Add health endpoint
    router.get("/health") { _, _ -> HTTPResponse.Status in
        return .ok
    }
    router.addRoutes(MarkerController(repository: repository).endpoints, atPath: "/markers")
    return router
}
