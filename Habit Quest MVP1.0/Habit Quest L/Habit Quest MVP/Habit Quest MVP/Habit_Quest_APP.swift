import SwiftUI
import CoreData

@main
struct Habit_Quest_APP: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView(context: persistenceController.container.viewContext)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
