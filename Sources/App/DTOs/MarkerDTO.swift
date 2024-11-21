import Fluent
import Vapor

struct MarkerDTO: Content {
    var id: UUID?
    var marker_type: String?
    
    func toModel() -> Marker {
        let model = Marker()
        
        model.id = self.id
        if let marker_type = self.marker_type {
            model.marker_type = marker_type
        }
        return model
    }
}
