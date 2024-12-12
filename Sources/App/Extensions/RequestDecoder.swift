import Foundation
import Hummingbird

/// Request body decoder
struct MarkerAuthRequestDecoder: RequestDecoder {
    func decode<T>(_ type: T.Type, from request: Request, context: some RequestContext) async throws -> T where T: Decodable {
        /// if no content-type header exists or it is an unknown content-type return bad request
        guard let header = request.headers[.contentType] else { throw HTTPError(.badRequest) }
        guard let mediaType = MediaType(from: header) else { throw HTTPError(.badRequest) }
        switch mediaType {
        case .applicationJson:
            return try await JSONDecoder().decode(type, from: request, context: context)
        case .applicationUrlEncoded:
            return try await URLEncodedFormDecoder().decode(type, from: request, context: context)
        default:
            throw HTTPError(.badRequest)
        }
    }
}
