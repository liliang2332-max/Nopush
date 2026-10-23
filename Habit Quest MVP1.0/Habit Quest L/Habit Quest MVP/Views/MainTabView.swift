import SwiftUI
import CoreData

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
                    AdventureRouletteView()
                        .padding(.horizontal)

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
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("今日任务")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if habitViewModel.habits.isEmpty {
                            EmptyHabitsView()
                        } else {
                            ForEach(habitViewModel.habits, id: \.self) { habit in
                                NavigationLink(destination: TimerView(habit: habit).environmentObject(expViewModel)) {
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
