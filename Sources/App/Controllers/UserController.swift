import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdBasicAuth
import HummingbirdFluent
import PostgresNIO

struct UserController {
    typealias Context = AppRequestContext
    let fluent: Fluent
    let sessionAuthenticator: SessionAuthenticator<Context, UserRepository>
    
    func addRoutes(to group: RouterGroup<Context>) {
        group.post(use: self.create)
        group.group("login")
            .add(middleware: BasicAuthenticator(users: self.sessionAuthenticator.users))
            .post(use: self.login)
        group.add(middleware: self.sessionAuthenticator)
            .get(use: self.current)
            .post("logout", use: self.logout)
    }

    /// Create marker entrypoint
    @Sendable func create(_ request: Request, context: some RequestContext) async throws -> EditedResponse<UserResponse> {
        let createUser = try await request.decode(as: CreateUserRequest.self, context: context)

        let user = try await User.create(
            name: createUser.name,
            email: createUser.email,
            password: createUser.password,
            db: self.fluent.db()
        )

        return .init(status: .created, response: UserResponse(from: user))
    }

    /// Login user and create session
    /// Used in tests, as user creation is done by ``WebController.loginDetails``
    @Sendable func login(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        guard let user = context.identity else { throw HTTPError(.unauthorized) }
        try context.sessions.setSession(user.requireID())
        return .ok
    }

    /// Login user and create session
    @Sendable func logout(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        context.sessions.clearSession()
        return .ok
    }

    /// Get current logged in user
    @Sendable func current(_ request: Request, context: Context) throws -> UserResponse {
        let user = try context.requireIdentity()
        return UserResponse(from: user)
    }
}