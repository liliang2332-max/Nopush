import SwiftUI

struct SettingsView: View {
	var body: some View {
		NavigationStack {
			Form {
				Section("关于") {
					Text("HabitQuest MVP 1.0")
				}
			}
			.navigationTitle("设置")
		}
	}
}
