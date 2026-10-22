import SwiftUI
import CoreData
import Combine

struct MainTabView: View {
    @StateObject private var expViewModel: ExperienceViewModel
    
    init(context: NSManagedObjectContext) {
        _expViewModel = StateObject(wrappedValue: ExperienceViewModel(context: context))
    }
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(expViewModel)
                .tabItem {
                    Label("主页", systemImage: "house.fill")
                }
            
            HabitListView()
                .environmentObject(expViewModel)
                .tabItem {
                    Label("习惯", systemImage: "list.bullet")
                }
            
            StatsView()
                .environmentObject(expViewModel)
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .environmentObject(expViewModel)
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.blue)
                        Text("LV \(expViewModel.level)")
                            .font(.headline)
                            .fontWeight(.bold)
                    }

                    Divider()
                        .frame(height: 20)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(expViewModel.currentEXP)/\(expViewModel.requiredEXPForCurrentLevel)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Divider()
                        .frame(height: 20)

                    HStack(spacing: 4) {
                        Image(systemName: "rosette")
                            .foregroundColor(.purple)
                        Text("S \(expViewModel.sBadgesThisLevel)/10")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(UIColor.systemBackground)))
                .fixedSize()
                .allowsHitTesting(false)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .fullScreenCover(isPresented: $expViewModel.showLevelUpModal) {
            LevelUpView(
                newLevel: expViewModel.levelUpInfo.newLevel,
                unlockedFeatures: expViewModel.levelUpInfo.features
            )
        }
    }
}

struct HomeView: View {
    @StateObject private var habitViewModel = HabitViewModel(context: PersistenceController.shared.container.viewContext)
    @EnvironmentObject var expViewModel: ExperienceViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 0) {
                        ForEach(AttributeType.allCases, id: \.self) { type in
                            SimpleAttributeCard(attributeType: type)
                                .environmentObject(expViewModel)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    HabitFormationStatusCard()
                        .padding(.horizontal)
                    
                    HomeTaskWheelCard(habitViewModel: habitViewModel)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("今日任务")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if habitViewModel.habits.isEmpty {
                            EmptyHabitsView()
                        } else {
                            ForEach(habitViewModel.habits, id: \.self) { habit in
                                NavigationLink {
                                    if (habit.value(forKey: "taskType") as? String) == "adventure" {
                                        AdventureTaskTimerView(habit: habit)
                                    } else {
                                        TimerView(habit: habit).environmentObject(expViewModel)
                                    }
                                } label: {
                                    HabitRowView(habit: habit)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .navigationTitle("Nopush")
        }
        .onAppear {
            habitViewModel.fetchHabits()
        }
    }
}

struct SimpleAttributeCard: View {
    let attributeType: AttributeType
    @EnvironmentObject var expViewModel: ExperienceViewModel
    
    var icon: String {
        switch attributeType {
        case .strength:
            return "figure.run"
        case .intelligence:
            return "book"
        case .agility:
            return "wind"
        case .charisma:
            return "sparkles"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.gray)
            
            Text(attributeType.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(expViewModel.attributes[attributeType] ?? 0)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 2)
                .frame(width: 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct HabitRowView: View {
    let habit: NSManagedObject
    
    var body: some View {
        HStack {
            if let typeString = habit.value(forKey: "attributeType") as? String,
               let type = AttributeType(rawValue: typeString) {
                Text(type.icon)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.value(forKey: "name") as? String ?? "未命名习惯")
                    .font(.headline)
                
                if let minutes = habit.value(forKey: "estimatedMinutes") as? Int16 {
                    Text("预计 \(minutes) 分钟")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct EmptyHabitsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("还没有习惯")
                .font(.headline)
            
            Text("点击下方「习惯」标签创建你的第一个习惯")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

struct StatsView: View {
    @StateObject private var statsVM: StatsViewModel
    @State private var currentLevel: Int = 1
    
    init() {
        _statsVM = StateObject(wrappedValue: StatsViewModel(context: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    TodayStatsSection(stats: statsVM.todayStats)
                    WeekStatsSection(stats: statsVM.weekStats)
                    
                    // ✅ 简化版：直接判断等级
                    if currentLevel >= 4 {
                        AdvancedStatsSection()
                    } else {
                        LockedAdvancedStatsSection {
                            print("功能未解锁")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("统计")
            .onAppear {
                statsVM.loadAllStats()
                loadUserLevel()
            }
        }
    }
    
    private func loadUserLevel() {
        let context = PersistenceController.shared.container.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
        
        do {
            if let profiles = try context.fetch(request) as? [NSManagedObject],
               let profile = profiles.first,
               let level = profile.value(forKey: "level") as? Int {
                currentLevel = level
            }
        } catch {
            print("❌ 加载等级失败: \(error)")
        }
    }
}

struct TodayStatsSection: View {
    let stats: TodayStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.gray)
                Text("今日数据")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("完成任务")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(stats.completedTasks)")
                                .font(.system(size: 36, weight: .bold))
                        }
                        
                        Spacer()
                        
                        Text("个")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green.opacity(0.2), lineWidth: 2)
                            )
                    )
                }
                
                HStack(spacing: 0) {
                    if stats.sRatingCount > 0 {
                        StatsCard(
                            icon: "star.fill",
                            iconColor: .gray,
                            title: "S 评级",
                            value: "\(stats.sRatingCount)",
                            unit: "个"
                        )
                    }
                    
                    if stats.totalExp > 0 {
                        StatsCard(
                            icon: "bolt.fill",
                            iconColor: .gray,
                            title: "经验值",
                            value: "+\(stats.totalExp)",
                            unit: "EXP"
                        )
                    }
                    
                    if stats.puristBadges + stats.challengerBadges > 0 {
                        StatsCard(
                            icon: "medal.fill",
                            iconColor: .gray,
                            title: "勋章",
                            value: "\(stats.puristBadges + stats.challengerBadges)",
                            unit: "个"
                        )
                    }
                    
                    if stats.streakDays > 0 {
                        StatsCard(
                            icon: "flame.fill",
                            iconColor: .gray,
                            title: "连续",
                            value: "\(stats.streakDays)",
                            unit: "天"
                        )
                    }
                }
                .padding(.vertical, 16)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
}

struct WeekStatsSection: View {
    let stats: WeekStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.gray)
                Text("本周统计")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                    Text("评级分布")
                        .font(.system(size: 18, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    RatingBar(label: "S", count: stats.sCount, total: stats.completedTasks, color: .yellow)
                    RatingBar(label: "A", count: stats.aCount, total: stats.completedTasks, color: .gray)
                    RatingBar(label: "B", count: stats.bCount, total: stats.completedTasks, color: .orange)
                    RatingBar(label: "C", count: stats.cCount, total: stats.completedTasks, color: .red)
                }
                .frame(height: 140)
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.yellow.opacity(0.2), lineWidth: 2)
                        )
                )
                
                VStack(spacing: 16) {
                    DetailRow(
                        icon: "medal.fill",
                        iconColor: .purple,
                        title: "勋章统计",
                        value: "纯粹者 \(stats.puristBadges) · 挑战者 \(stats.challengerBadges)"
                    )
                    
                    Divider()
                        .padding(.horizontal, 8)
                    
                    DetailRow(
                        icon: "clock.fill",
                        iconColor: .orange,
                        title: "总计用时",
                        value: "\(stats.totalHours)h \(stats.remainingMinutes)m",
                        subtitle: "平均 \(stats.avgMinutesPerTask) 分钟/任务"
                    )
                    
                    Divider()
                        .padding(.horizontal, 8)
                    
                    DetailRow(
                        icon: "checkmark.shield.fill",
                        iconColor: .green,
                        title: "准时完成率",
                        value: "\(Int(stats.onTimeRate * 100))%"
                    )
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            }
        }
    }
}

struct StatsCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 2)
                .frame(width: 30)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var subtitle: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
    }
}

struct RatingBar: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    
    var percent: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.25), lineWidth: 1.5)
                    )
                    .frame(height: 120)
                
                if percent > 0 {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: max(120 * CGFloat(percent), 8))
                }
            }
            .frame(height: 120)
            
            Text("\(count)")
                .font(.system(size: 22, weight: .bold))
        }
        .frame(maxWidth: .infinity)
    }
}

struct LockedAdvancedStatsSection: View {
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("高级趋势分析")
                .font(.title2)
                .fontWeight(.bold)
            
            Button(action: onTap) {
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("需要 LV 4 解锁")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("解锁后可查看详细趋势图表")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
            }
        }
    }
}

struct AdvancedStatsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("高级趋势分析")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Text("经验值增长曲线")
                Text("完成率趋势")
                Text("S评级获得率趋势")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var expViewModel: ExperienceViewModel
    @State private var showClearDataAlert = false
    @State private var showResetTutorialAlert = false
    
    private let context = PersistenceController.shared.container.viewContext
    
    var body: some View {
        NavigationStack {
            List {
                Section("账户") {
                    NavigationLink {
                        AccountDetailView()
                            .environmentObject(expViewModel)
                    } label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text("账户信息")
                        }
                    }
                }
                
                Section {
                    Button {
                        showResetTutorialAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.blue)
                            Text("重置教程")
                        }
                    }
                    
                    Button(role: .destructive) {
                        showClearDataAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("清除所有数据")
                        }
                    }
                } header: {
                    Text("数据管理")
                } footer: {
                    Text("清除数据将删除所有习惯、任务记录和进度，此操作不可恢复")
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink {
                        FeedbackView()
                    } label: {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                            Text("反馈建议")
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .alert("重置教程", isPresented: $showResetTutorialAlert) {
                Button("取消", role: .cancel) { }
                Button("确认重置") {
                    resetTutorial()
                }
            } message: {
                Text("将重新显示新手引导，是否继续？")
            }
            .alert("清除所有数据", isPresented: $showClearDataAlert) {
                Button("取消", role: .cancel) { }
                Button("确认清除", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("此操作将删除所有数据且不可恢复，确定要继续吗？")
            }
        }
    }
    
    private func resetTutorial() {
        print("重置教程")
    }
    
    private func clearAllData() {
        let entityNames = ["Habit", "TaskRecord", "HabitFormationTask", "DelayPackageHistory"]
        
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
                print("✅ 已清除 \(entityName)")
            } catch {
                print("❌ 清除 \(entityName) 失败: \(error)")
            }
        }
        
        let profileRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
        
        do {
            if let profiles = try context.fetch(profileRequest) as? [NSManagedObject],
               let profile = profiles.first {
                profile.setValue(Int32(0), forKey: "currentEXP")
                profile.setValue(Int32(0), forKey: "totalEXP")
                profile.setValue(Int32(1), forKey: "currentLevel")
                profile.setValue(Int32(0), forKey: "sBadgesThisLevel")
                profile.setValue(Int32(0), forKey: "strengthPoints")
                profile.setValue(Int32(0), forKey: "intelligencePoints")
                profile.setValue(Int32(0), forKey: "agilityPoints")
                profile.setValue(Int32(0), forKey: "charismaPoints")
                profile.setValue(Int32(5), forKey: "timeCoins")
                
                try context.save()
                print("✅ 用户档案已重置")
                
                expViewModel.loadUserProfile()
            }
        } catch {
            print("❌ 重置失败: \(error)")
        }
    }
}

struct AccountDetailView: View {
    @EnvironmentObject var expViewModel: ExperienceViewModel
    
    var body: some View {
        List {
            Section("等级信息") {
                HStack {
                    Text("当前等级")
                    Spacer()
                    Text("Lv \(expViewModel.level)")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("当前经验")
                    Spacer()
                    Text("\(expViewModel.currentEXP) / \(expViewModel.requiredEXPForCurrentLevel)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("总经验值")
                    Spacer()
                    Text("\(expViewModel.totalEXP) EXP")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("四维属性") {
                AttributeRow(type: .strength, value: expViewModel.attributes[.strength] ?? 0)
                AttributeRow(type: .intelligence, value: expViewModel.attributes[.intelligence] ?? 0)
                AttributeRow(type: .agility, value: expViewModel.attributes[.agility] ?? 0)
                AttributeRow(type: .charisma, value: expViewModel.attributes[.charisma] ?? 0)
                
                HStack {
                    Text("总和")
                        .fontWeight(.bold)
                    Spacer()
                    let total = (expViewModel.attributes[.strength] ?? 0) +
                               (expViewModel.attributes[.intelligence] ?? 0) +
                               (expViewModel.attributes[.agility] ?? 0) +
                               (expViewModel.attributes[.charisma] ?? 0)
                    Text("\(total) 点")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("账户详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AttributeRow: View {
    let type: AttributeType
    let value: Int
    
    var icon: String {
        switch type {
        case .strength:
            return "figure.run"
        case .intelligence:
            return "book"
        case .agility:
            return "wind"
        case .charisma:
            return "sparkles"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            Text(type.rawValue)
            Spacer()
            Text("\(value) 点")
                .fontWeight(.bold)
        }
    }
}

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedback = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("我们很重视您的意见")
                .font(.headline)
                .padding(.top, 20)
            
            TextEditor(text: $feedback)
                .frame(height: 200)
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
            
            Text("您的反馈将帮助我们改进产品")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button {
                submitFeedback()
            } label: {
                Text("提交反馈")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(feedback.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(feedback.isEmpty)
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
        .navigationTitle("反馈建议")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func submitFeedback() {
        print("提交反馈: \(feedback)")
        dismiss()
    }
}

struct HabitFormationStatusCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentTask: HabitFormationTask?
    @State private var showFormationView = false
    
    var body: some View {
        if let task = currentTask {
            Button(action: {
                showFormationView = true
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "target")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("21天挑战进行中")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        Text(task.habitName ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        let currentWeek = Int(task.currentWeek)
                        let progress: Int = {
                            switch currentWeek {
                            case 1: return Int(task.week1Progress)
                            case 2: return Int(task.week2Progress)
                            case 3: return Int(task.week3Progress)
                            default: return 0
                            }
                        }()
                        
                        HStack(spacing: 12) {
                            Text("Week \(currentWeek)/3")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.blue.opacity(0.15)))
                            
                            Text("本周 \(progress)/6")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.green.opacity(0.15)))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.5), Color.red.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showFormationView) {
                if let task = currentTask {
                    HabitFormationView(task: task)
                }
            }
            .onAppear {
                loadCurrentTask()
            }
        }
    }
    
    private func loadCurrentTask() {
        let formationManager = HabitFormationManager(context: viewContext)
        currentTask = formationManager.currentFormationTask
    }
}


struct StayHomeTask: Identifiable, Hashable {
    let id: Int
    let title: String
    let attribute: AttributeType
}

enum StayHomeTaskPool {
    static let tasks: [StayHomeTask] = {
        let groups: [(AttributeType, [String])] = [
            (.strength, [
                "跟着音乐活动身体 10 分钟", "做一组轻柔的全身拉伸", "练习 5 分钟肩颈放松",
                "做 10 次坐站练习", "沿着房间慢走 5 分钟", "跟一段低冲击居家操",
                "练习靠墙站立 2 分钟", "做一组手臂绕环和扩胸", "试试 5 分钟椅子瑜伽",
                "做一组小腿和脚踝活动", "跟着喜欢的歌自由舞动", "练习深呼吸和身体扫描",
                "做 10 次墙壁俯卧撑", "完成一组温和的腰背伸展", "做几次提踵练习",
                "在家走动并活动手脚 8 分钟", "练习平衡站立并扶稳支撑物", "做一组手腕和手指放松",
                "跟一段适合自己的拉伸视频", "做 5 分钟轻松原地踏步", "练习坐姿抬膝活动",
                "用泡沫轴或毛巾放松小腿", "做一组胸椎转动伸展", "完成 10 次深蹲到椅子",
                "挑一个身体部位做温和拉伸"
            ]),
            (.intelligence, [
                "读完手边书的 5 页", "听一段 10 分钟的知识播客", "学会一个新单词并造句",
                "写下今天想到的 3 个问题", "看一篇感兴趣的短文章", "学一个快捷键并马上试用",
                "复习 5 张单词卡片", "读一段历史或科普内容", "看一段短教程并记下要点",
                "写一段 100 字的小记录", "学一道新菜的做法", "整理一个最近想学的主题",
                "完成一道轻量的脑筋急转弯", "了解一个陌生词语的来历", "读一篇和工作无关的文章",
                "练习 10 分钟外语听力", "记下今天新学到的一件事", "看一段博物馆或自然纪录短片",
                "试着用自己的话解释一个概念", "给未来的自己写一张便签", "学一个简单的纸艺折法",
                "读几页以前买了还没读的书", "选一个主题做 10 分钟小研究", "练习写一首短诗或俳句",
                "把一个复杂想法画成简单示意图"
            ]),
            (.agility, [
                "整理书桌上的一个小区域", "清理手机里 10 张重复照片", "把一个抽屉整理 10 分钟",
                "给常用物品找一个固定位置", "收拾沙发周围的杂物", "整理电脑桌面上的文件",
                "把洗好的衣物叠好一小部分", "清洁一个常用杯子或水壶", "给植物浇水并擦掉枯叶",
                "整理冰箱里一个小角落", "更换床单或整理床铺", "擦拭门把手和常用开关",
                "把待办事项删减成最重要的 3 项", "整理包里的票据和小物件", "清理一个过期的备忘录列表",
                "把今天要用的东西提前放好", "把一双鞋擦干净并归位", "收纳一小篮散落物品",
                "整理一个文件夹或纸质文件", "清洁键盘或鼠标表面", "把快递纸箱折好并归类",
                "为明天准备一套衣服", "整理床头柜上的物品", "给冰箱列一份现有食材清单",
                "挑一个角落快速清理 5 分钟"
            ]),
            (.charisma, [
                "给一位朋友发消息问候近况", "给家人发一张今天的生活照片", "给重要的人认真说声谢谢",
                "给很久没联系的人发一句问候", "录一段语音分享最近的小发现", "写一张感谢便签留给身边的人",
                "和家人聊聊最近看过的好东西", "给朋友推荐一首最近喜欢的歌", "回复一条一直搁着的友善消息",
                "给自己写一句鼓励的话", "整理并分享一张温暖的旧照片", "问问朋友最近有没有需要帮忙的事",
                "给亲近的人发一个真诚的赞美", "和同住的人一起喝杯水聊 5 分钟", "给朋友分享一份简单食谱",
                "写下一个想感谢的人和原因", "给家人打一个简短电话", "向朋友介绍一本最近喜欢的书",
                "给邻居或同事发送一句友好问候", "约一位朋友下次一起散步", "给重要的人发一个拥抱表情",
                "分享一件今天让你开心的小事", "认真听完一首喜欢的歌并想起某个人", "写一张之后想送出的卡片",
                "对身边的人表达一次具体的感谢"
            ])
        ]
        return groups.enumerated().flatMap { groupIndex, group in
            group.1.enumerated().map { itemIndex, title in
                StayHomeTask(id: groupIndex * 25 + itemIndex, title: title, attribute: group.0)
            }
        }
    }()
}

private struct HomeTaskWheelCard: View {
    @ObservedObject var habitViewModel: HabitViewModel
    @EnvironmentObject private var expViewModel: ExperienceViewModel
    @State private var wheelRotation = 0.0
    @State private var isSpinning = false
    @State private var isShowingTask = false
    @State private var selectedTask: StayHomeTask?
    @AppStorage("nopush.adventureCoins") private var weeklyMistakeCoins = 5

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("宅家任务转盘")
                        .font(.title3.bold())
                    Text("从 100 件小事里抽一个，轻松开始")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }

            HStack {
                Label("本周犯错金币", systemImage: "bitcoinsign.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(weeklyMistakeCoins)/5")
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 0.92, green: 0.38, blue: 0.35))
            }
            .padding(.horizontal, 4)

            TaskWheelGraphic()
                .frame(width: 196, height: 196)
                .rotationEffect(.degrees(wheelRotation))
                .accessibilityHidden(true)

            Button {
                guard !isSpinning else { return }
                selectedTask = StayHomeTaskPool.tasks.randomElement()
                isSpinning = true
                withAnimation(.easeOut(duration: 1.7)) {
                    wheelRotation += Double.random(in: 1440...2160)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
                    isSpinning = false
                    isShowingTask = selectedTask != nil
                }
            } label: {
                Label(isSpinning ? "正在抽取…" : "转一个任务", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.indigo, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isSpinning)
            .accessibilityIdentifier("homeTaskWheel.drawButton")
        }
        .padding(18)
        .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $isShowingTask, onDismiss: { selectedTask = nil }) {
            if let selectedTask {
                NavigationStack {
                    HomeTaskDetailView(task: selectedTask) { minutes in
                        habitViewModel.createHabit(
                            name: selectedTask.title,
                            attributeType: selectedTask.attribute.rawValue,
                            estimatedMinutes: Int16(minutes),
                            isFormationTask: false,
                            taskType: "adventure"
                        )
                    }
                    .environmentObject(expViewModel)
                }
            }
        }
    }
}

private struct TaskWheelGraphic: View {
    private let colors: [Color] = [
        Color.orange.opacity(0.78), Color.pink.opacity(0.72),
        Color.purple.opacity(0.72), Color.blue.opacity(0.72),
        Color.teal.opacity(0.78), Color.yellow.opacity(0.82)
    ]

    var body: some View {
        ZStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2
                for index in 0..<12 {
                    var wedge = Path()
                    wedge.move(to: center)
                    wedge.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(Double(index) * 30 - 90),
                        endAngle: .degrees(Double(index + 1) * 30 - 90),
                        clockwise: false
                    )
                    wedge.closeSubpath()
                    context.fill(wedge, with: .color(colors[index % colors.count]))
                    context.stroke(wedge, with: .color(.white.opacity(0.7)), lineWidth: 2)
                }
            }
            .clipShape(Circle())
            Circle()
                .fill(.white)
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.orange)
                }
            Circle()
                .stroke(.white, lineWidth: 4)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }
}

private struct HomeTaskDetailView: View {
    let task: StayHomeTask
    let onAddToToday: (Int) -> Habit
    @EnvironmentObject private var expViewModel: ExperienceViewModel
    @State private var estimatedMinutes = 15
    @State private var createdHabit: Habit?

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 12) {
                Text(task.attribute.icon)
                    .font(.system(size: 42))
                Text(task.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(task.attribute.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(task.attribute.color)
            }
            .padding(.top, 28)

            Text("按今天的状态做轻量版也可以。时间到了就停，不必追求一次做完。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            HStack {
                Text("预计用时")
                    .font(.headline)
                Spacer()
                TextField("分钟", value: $estimatedMinutes, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 72)
                    .textFieldStyle(.roundedBorder)
                Text("分钟")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

            if let createdHabit {
                VStack(spacing: 12) {
                    Text("已加入今日任务")
                        .font(.headline)
                        .foregroundStyle(.green)
                    NavigationLink {
                        AdventureTaskTimerView(habit: createdHabit)
                    } label: {
                        Label("进入计时页", systemImage: "timer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color.indigo, in: RoundedRectangle(cornerRadius: 14))
                    }
                    Text("计时器会在你点下「开始」后启动。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    createdHabit = onAddToToday(estimatedMinutes)
                } label: {
                    Label("加入今日任务", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(estimatedMinutes > 0 ? Color.indigo : Color.gray, in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(estimatedMinutes <= 0)
                .accessibilityIdentifier("homeTaskWheel.addTaskButton")
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .navigationTitle("任务详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}



private struct AdventureTaskTimerView: View {
    private enum Phase { case ready, running, completed, failed }
    let habit: Habit

    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("nopush.adventureCoins") private var weeklyMistakeCoins = 5
    @AppStorage("nopush.adventureCoinWindow") private var coinWindowStart = 0.0
    @State private var phase: Phase = .ready
    @State private var elapsedSeconds = 0
    @State private var isRunning = false
    @State private var hasUsedExtension = false
    @State private var extensionOfferShown = false
    @State private var showing80Choice = false
    @State private var showingRechargeNotice = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let coral = Color(red: 1.0, green: 0.42, blue: 0.42)
    private let teal = Color(red: 0.31, green: 0.80, blue: 0.77)

    private var taskName: String { habit.value(forKey: "name") as? String ?? "今日冒险" }
    private var durationMinutes: Int {
        max(1, Int(habit.value(forKey: "estimatedMinutes") as? Int16 ?? 20))
    }
    private var baseDurationSeconds: Int { durationMinutes * 60 }
    private var deadlineSeconds: Int { baseDurationSeconds + (hasUsedExtension ? 15 * 60 : 0) }
    private var progress: Double {
        min(Double(elapsedSeconds) / Double(max(1, baseDurationSeconds)), 1.0)
    }
    private var remainingSeconds: Int { max(0, deadlineSeconds - elapsedSeconds) }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    switch phase {
                    case .ready: readyContent
                    case .running: runningContent
                    case .completed: completedContent
                    case .failed: failedContent
                    }
                }
                .padding(20)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("今日冒险")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshWeeklyCoinsIfNeeded)
        .onReceive(ticker) { _ in tick() }
        .confirmationDialog("到达自设时长的 80%", isPresented: $showing80Choice, titleVisibility: .visible) {
            Button("购买延时包 · +15 分钟") {
                hasUsedExtension = true
                extensionOfferShown = true
                isRunning = true
                phase = .running
            }
            Button("按原计划继续") {
                extensionOfferShown = true
                isRunning = true
                phase = .running
            }
            Button("这次先结束", role: .destructive) {
                isRunning = false
                phase = .failed
            }
        } message: {
            Text("还差一点点。延时是可选的；延时包的货币和价格尚未设定。")
        }
        .alert("充值金币", isPresented: $showingRechargeNotice) {
            Button("知道了", role: .cancel) { }
        } message: {
            Text("当前原型尚未接入真实支付。你可以清零当前任务后重新开始。")
        }
    }

    private var readyContent: some View {
        VStack(spacing: 22) {
            Image(systemName: "sparkles")
                .font(.system(size: 42))
                .foregroundStyle(coral)
                .padding(.top, 24)
            Text(taskName).font(.title2.bold()).multilineTextAlignment(.center)
            Text("给自己 \(durationMinutes) 分钟。准备好了再开始。")
                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            timerRing(time: "00:00", note: "尚未开始", fraction: 0)
            Text("计时不会自动开始，点下按钮后才会启动。")
                .font(.caption).foregroundStyle(.secondary)
            Button {
                elapsedSeconds = 0
                hasUsedExtension = false
                extensionOfferShown = false
                phase = .running
                isRunning = true
            } label: {
                Label("开始计时", systemImage: "play.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15)
                    .foregroundStyle(.white).background(coral, in: RoundedRectangle(cornerRadius: 16))
            }
            .accessibilityIdentifier("adventureTimer.start")
        }
        .padding(18).frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
    }

    private var runningContent: some View {
        VStack(spacing: 20) {
            Text("正在冒险").font(.caption.bold()).foregroundStyle(teal)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(teal.opacity(0.12), in: Capsule())
            Text(taskName).font(.title2.bold()).multilineTextAlignment(.center)
            Text(hasUsedExtension ? "延时包已使用 · 最多延长 15 分钟" : "你设定了 \(durationMinutes) 分钟")
                .font(.subheadline).foregroundStyle(.secondary)
            timerRing(
                time: formattedTime(remainingSeconds),
                note: hasUsedExtension && elapsedSeconds >= baseDurationSeconds ? "延时进行中" : "剩余时间",
                fraction: progress
            )
            ProgressView(value: progress).tint(progress >= 0.8 ? coral : teal)
            Text("已完成 \(Int(progress * 100))%")
                .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            Button {
                isRunning = false
                HabitViewModel(context: context).completeTask(habit: habit)
                phase = .completed
            } label: {
                Label("我完成了", systemImage: "checkmark")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15)
                    .foregroundStyle(.white).background(teal, in: RoundedRectangle(cornerRadius: 16))
            }
            Button("这次先结束") { isRunning = false; phase = .failed }
                .foregroundStyle(.secondary)
            if !hasUsedExtension {
                Text("到达你设定时间的 80% 时，可以选择是否延时。")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }
        .padding(18).frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
    }

    private var completedContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark").font(.system(size: 36, weight: .bold))
                .foregroundStyle(teal).frame(width: 78, height: 78)
                .background(teal.opacity(0.13), in: Circle()).padding(.top, 22)
            Text("这件小事，你做到了。").font(.title2.bold()).multilineTextAlignment(.center)
            Text(taskName).font(.headline).foregroundStyle(.secondary)
            Text("不用追求完美。你愿意开始，就已经很棒。")
                .font(.body).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button("完成") { dismiss() }
                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15)
                .foregroundStyle(.white).background(coral, in: RoundedRectangle(cornerRadius: 16))
        }
        .padding(22).frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
    }

    private var failedContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 34, weight: .semibold)).foregroundStyle(Color.orange)
                .frame(width: 72, height: 72).background(Color.orange.opacity(0.12), in: Circle())
                .padding(.top, 16)
            Text("这次还没完成").font(.title2.bold())
            Text("没关系，准备好时可以再来一次。")
                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)

            if weeklyMistakeCoins > 0 {
                Text("本周还剩 \(weeklyMistakeCoins) 枚金币。用 1 枚购买一次犯错机会，再挑战这项任务。")
                    .font(.subheadline).multilineTextAlignment(.center).padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
                Button {
                    weeklyMistakeCoins -= 1
                    elapsedSeconds = 0
                    hasUsedExtension = false
                    extensionOfferShown = false
                    phase = .ready
                } label: {
                    Label("用 1 枚金币买一次重来机会", systemImage: "bitcoinsign.circle.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .foregroundStyle(.white).background(coral, in: RoundedRectangle(cornerRadius: 16))
                }
            } else {
                Text("本周金币用完了。你可以充值，或清零当前任务后重新开始。")
                    .font(.subheadline).multilineTextAlignment(.center).padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
                Button("充值金币") { showingRechargeNotice = true }
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .foregroundStyle(.white).background(coral, in: RoundedRectangle(cornerRadius: 16))
                Button("清零并重新开始任务", role: .destructive) { clearCurrentTaskAndReturn() }
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            }
            Button("放下这项任务，回到转盘") { clearCurrentTaskAndReturn() }
                .font(.subheadline).foregroundStyle(.secondary).padding(.top, 4)
        }
        .padding(20).frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
    }

    private func timerRing(time: String, note: String, fraction: Double) -> some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.12), lineWidth: 13)
            Circle().trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(coral, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 6) {
                Text(time).font(.system(size: 42, weight: .bold, design: .rounded)).monospacedDigit()
                Text(note).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(width: 220, height: 220).padding(.vertical, 8)
    }

    private func tick() {
        guard phase == .running, isRunning, !showing80Choice else { return }
        elapsedSeconds += 1
        if !extensionOfferShown && !hasUsedExtension &&
            elapsedSeconds >= Int(Double(baseDurationSeconds) * 0.8) {
            elapsedSeconds = Int(Double(baseDurationSeconds) * 0.8)
            extensionOfferShown = true
            showing80Choice = true
            return
        }
        if elapsedSeconds >= deadlineSeconds {
            elapsedSeconds = deadlineSeconds
            isRunning = false
            phase = .failed
        }
    }

    private func refreshWeeklyCoinsIfNeeded() {
        let now = Date().timeIntervalSince1970
        if coinWindowStart == 0 {
            coinWindowStart = now
        } else if now - coinWindowStart >= 7 * 24 * 60 * 60 {
            weeklyMistakeCoins = 5
            coinWindowStart = now
        }
    }

    private func clearCurrentTaskAndReturn() {
        isRunning = false
        context.delete(habit)
        do { try context.save() }
        catch { print("删除冒险任务失败：\(error.localizedDescription)") }
        dismiss()
    }

    private func formattedTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
