import Foundation
import CoreData

class CoreDataService {
    static let shared = CoreDataService()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ApartmentRouteMapper")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    func save() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // MARK: - Apartment Operations
    func fetchApartments() -> [Apartment] {
        let request = ApartmentEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ApartmentEntity.name, ascending: true)]
        
        do {
            let entities = try viewContext.fetch(request)
            return entities.compactMap { $0.toApartment() }
        } catch {
            print("Failed to fetch apartments: \(error)")
            return []
        }
    }
    
    func saveApartment(_ apartment: Apartment) {
        let entity = ApartmentEntity(context: viewContext)
        entity.updateFromApartment(apartment)
        save()
    }
    
    func updateApartment(_ apartment: Apartment) {
        let request = ApartmentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", apartment.id as CVarArg)
        
        do {
            if let entity = try viewContext.fetch(request).first {
                entity.updateFromApartment(apartment)
                save()
            }
        } catch {
            print("Failed to update apartment: \(error)")
        }
    }
    
    func deleteApartment(_ apartment: Apartment) {
        let request = ApartmentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", apartment.id as CVarArg)
        
        do {
            if let entity = try viewContext.fetch(request).first {
                viewContext.delete(entity)
                save()
            }
        } catch {
            print("Failed to delete apartment: \(error)")
        }
    }
    
    // MARK: - Route Operations
    func fetchRoutes() -> [SavedRoute] {
        let request = RouteEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RouteEntity.updatedAt, ascending: false)]
        
        do {
            let entities = try viewContext.fetch(request)
            return entities.compactMap { $0.toSavedRoute() }
        } catch {
            print("Failed to fetch routes: \(error)")
            return []
        }
    }
    
    func saveRoute(name: String, apartments: [Apartment], totalDistance: CLLocationDistance, totalDuration: TimeInterval, isOptimized: Bool) -> SavedRoute? {
        let entity = RouteEntity(context: viewContext)
        entity.id = UUID()
        entity.name = name
        entity.totalDistance = totalDistance
        entity.totalDuration = totalDuration
        entity.isOptimized = isOptimized
        entity.createdAt = Date()
        entity.updatedAt = Date()
        
        // Save apartment order
        let apartmentEntities = apartments.compactMap { apartment -> ApartmentEntity? in
            let request = ApartmentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", apartment.id as CVarArg)
            return try? viewContext.fetch(request).first
        }
        
        entity.apartments = NSOrderedSet(array: apartmentEntities)
        
        save()
        return entity.toSavedRoute()
    }
    
    func deleteRoute(_ route: SavedRoute) {
        let request = RouteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", route.id as CVarArg)
        
        do {
            if let entity = try viewContext.fetch(request).first {
                viewContext.delete(entity)
                save()
            }
        } catch {
            print("Failed to delete route: \(error)")
        }
    }
}

// MARK: - Core Data Extensions
extension ApartmentEntity {
    func toApartment() -> Apartment? {
        guard let id = id, let name = name, let address = address else { return nil }
        
        return Apartment(
            id: id,
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude,
            notes: notes,
            visitOrder: Int(visitOrder)
        )
    }
    
    func updateFromApartment(_ apartment: Apartment) {
        self.id = apartment.id
        self.name = apartment.name
        self.address = apartment.address
        self.latitude = apartment.latitude
        self.longitude = apartment.longitude
        self.notes = apartment.notes
        self.visitOrder = Int32(apartment.visitOrder ?? 0)
        self.estimatedVisitDuration = apartment.estimatedVisitDuration
    }
}

extension RouteEntity {
    func toSavedRoute() -> SavedRoute? {
        guard let id = id,
              let name = name,
              let createdAt = createdAt,
              let updatedAt = updatedAt,
              let apartmentSet = apartments else { return nil }
        
        let apartmentArray = apartmentSet.array as? [ApartmentEntity] ?? []
        let apartments = apartmentArray.compactMap { $0.toApartment() }
        
        return SavedRoute(
            id: id,
            name: name,
            apartments: apartments,
            totalDistance: totalDistance,
            totalDuration: totalDuration,
            isOptimized: isOptimized,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Saved Route Model
struct SavedRoute: Identifiable {
    let id: UUID
    let name: String
    let apartments: [Apartment]
    let totalDistance: CLLocationDistance
    let totalDuration: TimeInterval
    let isOptimized: Bool
    let createdAt: Date
    let updatedAt: Date
}