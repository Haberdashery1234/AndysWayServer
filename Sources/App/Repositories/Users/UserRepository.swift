import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdBasicAuth
import HummingbirdFluent

struct UserRepository: UserSessionRepository, UserPasswordRepository {
    typealias User = App.User
    typealias Session = UUID

    let fluent: Fluent

    func getUser(from session: UUID, context: UserRepositoryContext) async throws -> User? {
        try await User.find(session, on: self.fluent.db())
    }

    func getUser(named email: String, context: UserRepositoryContext) async throws -> User? {
        try await User.query(on: self.fluent.db())
            .filter(\.$email == email)
            .first()
    }
}
