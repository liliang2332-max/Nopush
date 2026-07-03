import SwiftUI

struct StatsView: View {
	@StateObject private var vm = StatsViewModel()

	var body: some View {
		NavigationStack {
			List {
				Section("今日") {
					Text("完成习惯数：\(vm.todayCompletedCount)")
				}
				Section("连续") {
					Text("连续打卡：\(vm.currentStreakDays) 天")
				}
				Section("本周趋势") {
					ForEach(vm.weeklyTrend) { p in
						HStack { Text(p.date, style: .date); Spacer(); Text("\(p.points)") }
					}
				}
			}
			.navigationTitle("统计")
		}
		.onAppear { vm.reload() }
	}
}
