import SwiftUI

@main
struct HabitQuestApp: App {
	@Environment(\.scenePhase) private var scenePhase
	private let persistenceController = PersistenceController.shared

	var body: some Scene {
		WindowGroup {
			RootTabView()
				.environment(\.managedObjectContext, persistenceController.container.viewContext)
		}
		.onChange(of: scenePhase) { newPhase in
			if newPhase == .background {
				persistenceController.saveContext()
			}
		}
	}
}
