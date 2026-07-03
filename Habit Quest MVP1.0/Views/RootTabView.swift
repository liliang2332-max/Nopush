import SwiftUI

struct RootTabView: View {
	var body: some View {
		TabView {
			HomeView()
				.tabItem { Label("Home", systemImage: "house.fill") }

			HabitsView()
				.tabItem { Label("Habits", systemImage: "checkmark.circle") }

			StatsView()
				.tabItem { Label("Stats", systemImage: "chart.bar.doc.horizontal") }

			SettingsView()
				.tabItem { Label("Settings", systemImage: "gearshape") }
		}
	}
}
