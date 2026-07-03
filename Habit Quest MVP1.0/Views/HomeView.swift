import SwiftUI

struct HomeView: View {
	@StateObject private var statsVM = StatsViewModel()
	@StateObject private var profileVM = UserProfileViewModel()

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 16) {
					attributeGrid
					Divider()
					todaySummary
				}
				.padding()
			}
			.navigationTitle("HabitQuest")
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Text("EXP: \(profileVM.currentEXP)")
						.font(.headline)
				}
			}
		}
		.onAppear { statsVM.reload() }
	}

	private var attributeGrid: some View {
		LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
			ForEach(AttributeType.allCases) { type in
				AttributeCardView(type: type, today: 0, total: profileVM.attributes[type] ?? 0)
			}
		}
	}

	private var todaySummary: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("今日完成：\(statsVM.todayCompletedCount)")
			Text("连续打卡：\(statsVM.currentStreakDays) 天")
			Text("本周趋势点：\(statsVM.weeklyTrend.count)")
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}
