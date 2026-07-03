import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        let profile = NSEntityDescription.insertNewObject(forEntityName: "UserProfile", into: viewContext)
        profile.setValue(UUID(), forKey: "id")
        profile.setValue(Int32(150), forKey: "currentEXP")
        profile.setValue(Int32(500), forKey: "totalEXP")
        profile.setValue(Int16(3), forKey: "level")
        profile.setValue(Int16(4), forKey: "sBadgesThisLevel")
        profile.setValue(Int32(50), forKey: "strengthPoints")
        profile.setValue(Int32(40), forKey: "intelligencePoints")
        profile.setValue(Int32(30), forKey: "agilityPoints")
        profile.setValue(Int32(20), forKey: "charismaPoints")
        profile.setValue(Date(), forKey: "createdDate")
        profile.setValue(Date(), forKey: "lastActiveDate")
        
        for i in 0..<3 {
            let habit = NSEntityDescription.insertNewObject(forEntityName: "Habit", into: viewContext)
            habit.setValue(UUID(), forKey: "id")
            habit.setValue("习惯 \(i+1)", forKey: "name")
            habit.setValue(AttributeType.allCases[i].rawValue, forKey: "attributeType")
            habit.setValue(Int16(30 + i * 15), forKey: "estimatedMinutes")
            habit.setValue(Date(), forKey: "createdDate")
            habit.setValue(true, forKey: "isActive")
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Habit_Quest_MVP")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        initializeUserProfile()
    }
    
    private func initializeUserProfile() {
        let context = container.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
        
        do {
            let count = try context.count(for: request)
            if count == 0 {
                let profile = NSEntityDescription.insertNewObject(forEntityName: "UserProfile", into: context)
                profile.setValue(UUID(), forKey: "id")
                profile.setValue(Int32(0), forKey: "currentEXP")
                profile.setValue(Int32(0), forKey: "totalEXP")
                profile.setValue(Int16(1), forKey: "level")
                profile.setValue(Int16(0), forKey: "sBadgesThisLevel")
                profile.setValue(Int32(0), forKey: "strengthPoints")
                profile.setValue(Int32(0), forKey: "intelligencePoints")
                profile.setValue(Int32(0), forKey: "agilityPoints")
                profile.setValue(Int32(0), forKey: "charismaPoints")
                profile.setValue(Date(), forKey: "createdDate")
                profile.setValue(Date(), forKey: "lastActiveDate")
                
                try context.save()
            }
        } catch {
            print("Failed to initialize user profile: \(error)")
        }
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Failed to save context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
