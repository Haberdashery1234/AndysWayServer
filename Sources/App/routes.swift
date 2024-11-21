import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("markers") { req async -> [Marker] in
        let markers = req
        return markers
    }
    
    app.put("markers") { req async -> [Marker] in
        
    }

    try app.register(collection: MarkerController())
}
