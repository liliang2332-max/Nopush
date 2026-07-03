import SwiftUI
import CoreData

// 习惯列表视图
struct HabitListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var expViewModel: ExperienceViewModel
    @StateObject private var habitViewModel: HabitViewModel
    @State private var showingAddSheet = false
    
    init() {
        _habitViewModel = StateObject(wrappedValue: HabitViewModel(
            context: PersistenceController.shared.container.viewContext
        ))
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 时间币卡片
                Section {
                    TimeCoinCard(viewModel: habitViewModel)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                
                // 习惯列表
                if habitViewModel.habits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("创建你的第一个习惯")
                            .font(.headline)
                        
                        Button {
                            showingAddSheet = true
                        } label: {
                            Text("添加习惯")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(habitViewModel.habits, id: \.self) { habit in
                        // ✅ 修复:只传habit参数
                        NavigationLink(destination: TimerView(habit: habit).environmentObject(expViewModel)) {
                            HabitListRow(habit: habit)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                habitViewModel.deleteHabit(habit)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("我的习惯")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !habitViewModel.habits.isEmpty {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddHabitView(habitViewModel: habitViewModel)
            }
            .onAppear {
                habitViewModel.fetchHabits()
                habitViewModel.updateAvailableTimeCoins()
            }
        }
    }
}

// 时间币卡片
struct TimeCoinCard: View {
    @ObservedObject var viewModel: HabitViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本周时间币")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        Text("\(viewModel.availableTimeCoins)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("/ 5")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("下次重置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let nextReset = viewModel.getNextResetDate() {
                        Text(nextReset, style: .relative)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("时间币可用于习惯养成任务的灵活暂停")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// 习惯列表行
struct HabitListRow: View {
    let habit: NSManagedObject
    
    var body: some View {
        HStack(spacing: 16) {
            if let typeString = habit.value(forKey: "attributeType") as? String,
               let type = AttributeType(rawValue: typeString) {
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(type.icon)
                        .font(.title2)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(habit.value(forKey: "name") as? String ?? "未命名习惯")
                        .font(.headline)
                    
                    if habit.value(forKey: "isFormationTask") as? Bool == true {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                HStack {
                    if let typeString = habit.value(forKey: "attributeType") as? String,
                       let type = AttributeType(rawValue: typeString) {
                        Text(type.rawValue)
                            .font(.caption)
                            .foregroundColor(type.color)
                    }
                    
                    Text("·")
                        .foregroundColor(.secondary)
                    
                    if let minutes = habit.value(forKey: "estimatedMinutes") as? Int16 {
                        Text("\(minutes) 分钟")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let streak = habit.value(forKey: "currentStreak") as? Int16, streak > 0 {
                        Text("·")
                            .foregroundColor(.secondary)
                        
                        Text("连续\(streak)天")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// 添加习惯视图
struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var habitViewModel: HabitViewModel
    
    @State private var name = ""
    @State private var selectedAttribute: AttributeType = .strength
    @State private var estimatedMinutes = 30
    @State private var taskType: TaskType = .daily
    @State private var showFormationWarning = false
    
    private var formationManager: HabitFormationManager {
        HabitFormationManager(context: viewContext)
    }
    
    enum TaskType: String, CaseIterable {
        case daily = "日常任务"
        case formation = "习惯养成任务"
        
        var description: String {
            switch self {
            case .daily:
                return "可以无限制创建，每次完成获得经验和属性点"
            case .formation:
                return "21天挑战，同时只能进行1个，完成后获得大量奖励"
            }
        }
        
        var icon: String {
            switch self {
            case .daily:
                return "checkmark.circle"
            case .formation:
                return "flame"
            }
        }
    }
    
    private func getAttributeIcon(_ type: AttributeType) -> String {
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
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("习惯名称", text: $name)
                    
                    Picker("属性类型", selection: $selectedAttribute) {
                        ForEach(AttributeType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: getAttributeIcon(type))
                                    .foregroundColor(.gray)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    
                    Stepper("预计时间：\(estimatedMinutes) 分钟", value: $estimatedMinutes, in: 5...180, step: 5)
                }
                
                Section {
                    VStack(spacing: 16) {
                        Text("任务类型")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            Button {
                                taskType = .daily
                            } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 32))
                                        .foregroundColor(taskType == .daily ? .blue : .gray)
                                    
                                    Text("日常任务")
                                        .font(.headline)
                                        .foregroundColor(taskType == .daily ? .primary : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(taskType == .daily ? Color.blue.opacity(0.1) : Color(UIColor.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(taskType == .daily ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                if formationManager.canCreateNewFormation() {
                                    taskType = .formation
                                } else {
                                    showFormationWarning = true
                                }
                            } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: "flame")
                                        .font(.system(size: 32))
                                        .foregroundColor(taskType == .formation ? .orange : .gray)
                                    
                                    Text("习惯养成")
                                        .font(.headline)
                                        .foregroundColor(taskType == .formation ? .primary : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(taskType == .formation ? Color.orange.opacity(0.1) : Color(UIColor.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(taskType == .formation ? Color.orange : Color.clear, lineWidth: 2)
                                        )
                                )
                                .opacity(formationManager.canCreateNewFormation() ? 1.0 : 0.5)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(taskType.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if taskType == .formation {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("每周需完成5/6天，共3周，失败最多重试2次")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                
                                if !formationManager.canCreateNewFormation() {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text("当前已有一个习惯养成任务正在进行")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("选择任务类型")
                }
                
                Section("属性说明") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedAttribute.description)
                            .font(.subheadline)
                        
                        Text("示例：\(selectedAttribute.examples)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("添加习惯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveHabit()
                    }
                    .disabled(name.isEmpty || (taskType == .formation && !formationManager.canCreateNewFormation()))
                }
            }
            .alert("无法创建习惯养成任务", isPresented: $showFormationWarning) {
                Button("知道了", role: .cancel) { }
            } message: {
                Text("当前已有一个习惯养成任务正在进行，请先完成或放弃现有任务。")
            }
        }
    }
    
    private func saveHabit() {
        if taskType == .formation {
            if !formationManager.canCreateNewFormation() {
                showFormationWarning = true
                return
            }
        }
        
        let isFormation = taskType == .formation
        
        habitViewModel.createHabit(
            name: name,
            attributeType: selectedAttribute.rawValue,
            estimatedMinutes: Int16(estimatedMinutes),
            isFormationTask: isFormation
        )
        
        dismiss()
    }
}
