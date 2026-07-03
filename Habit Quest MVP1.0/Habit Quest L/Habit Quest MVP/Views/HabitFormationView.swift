import SwiftUI
import CoreData

/// 21天习惯养成进度视图
struct HabitFormationView: View {
    let task: NSManagedObject
    @Environment(\.dismiss) var dismiss
    
    // 从task中提取数据
    private var habitName: String {
        task.value(forKey: "habitName") as? String ?? "未知习惯"
    }
    
    private var currentWeek: Int {
        Int(task.value(forKey: "currentWeek") as? Int16 ?? 1)
    }
    
    private var startDate: Date {
        task.value(forKey: "startDate") as? Date ?? Date()
    }
    
    private var status: String {
        task.value(forKey: "status") as? String ?? "ongoing"
    }
    
    private var isInMaintenance: Bool {
        task.value(forKey: "isInMaintenance") as? Bool ?? false
    }
    
    private var week1Progress: Int {
        Int(task.value(forKey: "week1Progress") as? Int16 ?? 0)
    }
    
    private var week2Progress: Int {
        Int(task.value(forKey: "week2Progress") as? Int16 ?? 0)
    }
    
    private var week3Progress: Int {
        Int(task.value(forKey: "week3Progress") as? Int16 ?? 0)
    }
    
    private var week1Retries: Int {
        Int(task.value(forKey: "week1Retries") as? Int16 ?? 0)
    }
    
    private var week2Retries: Int {
        Int(task.value(forKey: "week2Retries") as? Int16 ?? 0)
    }
    
    private var week3Retries: Int {
        Int(task.value(forKey: "week3Retries") as? Int16 ?? 0)
    }
    
    private var estimatedCompletionDate: Date {
        let daysRemaining = (3 - currentWeek + 1) * 7
        return Calendar.current.date(byAdding: .day, value: daysRemaining, to: Date()) ?? Date()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部标题区
                    headerSection
                    
                    // 总进度
                    overallProgressSection
                    
                    // 3周进度展示
                    weekProgressSection
                    
                    // 当前状态
                    currentStatusSection
                    
                    // 激励文案
                    motivationSection
                }
                .padding()
            }
            .navigationTitle("21天挑战")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
    
    // MARK: - 顶部标题区
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // 习惯图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Text("🎯")
                    .font(.system(size: 40))
            }
            
            // 习惯名称
            Text(habitName)
                .font(.title)
                .fontWeight(.bold)
            
            // 状态标签
            if isInMaintenance {
                Text("维持模式")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.green))
            } else if status == "completed" {
                Text("已完成")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.green))
            } else if status == "failed" {
                Text("已失败")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.red))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - 总进度
    
    private var overallProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("总进度")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Week \(currentWeek)/3")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("预计完成")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(estimatedCompletionDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(currentWeek) / 3.0, height: 20)
                }
            }
            .frame(height: 20)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - 3周进度展示
    
    private var weekProgressSection: some View {
        VStack(spacing: 16) {
            WeekProgressCard(
                weekNumber: 1,
                progress: week1Progress,
                retries: week1Retries,
                isCurrentWeek: currentWeek == 1,
                isCompleted: currentWeek > 1
            )
            
            WeekProgressCard(
                weekNumber: 2,
                progress: week2Progress,
                retries: week2Retries,
                isCurrentWeek: currentWeek == 2,
                isCompleted: currentWeek > 2
            )
            
            WeekProgressCard(
                weekNumber: 3,
                progress: week3Progress,
                retries: week3Retries,
                isCurrentWeek: currentWeek == 3,
                isCompleted: status == "completed" || isInMaintenance
            )
        }
    }
    
    // MARK: - 当前状态
    
    private var currentStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前状态")
                .font(.headline)
            
            if isInMaintenance {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("维持模式")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("继续保持每周5/6的目标，每周达标可获得 +50 EXP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else if status == "ongoing" {
                let currentProgress = currentWeek == 1 ? week1Progress : (currentWeek == 2 ? week2Progress : week3Progress)
                let currentRetries = currentWeek == 1 ? week1Retries : (currentWeek == 2 ? week2Retries : week3Retries)
                
                HStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("本周进度：\(currentProgress)/6")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("剩余重试次数：\(2 - currentRetries)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - 激励文案
    
    private var motivationSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundColor(.yellow)
            
            Text(getMotivationText())
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.1))
        )
    }
    
    private func getMotivationText() -> String {
        if isInMaintenance {
            return "恭喜你完成了21天挑战！继续保持习惯，让它成为你生活的一部分。"
        } else if status == "completed" {
            return "太棒了！你成功完成了21天挑战，这个习惯已经深深刻在你的生活中。"
        } else if status == "failed" {
            return "这次没有成功，但不要气馁。重新开始，你一定可以做到！"
        } else {
            switch currentWeek {
            case 1:
                return "万事开头难，坚持下去，你会看到改变！"
            case 2:
                return "你已经走过了三分之一，继续加油！"
            case 3:
                return "最后冲刺！胜利就在眼前！"
            default:
                return "坚持就是胜利！"
            }
        }
    }
}

// MARK: - 单周进度卡片

struct WeekProgressCard: View {
    let weekNumber: Int
    let progress: Int
    let retries: Int
    let isCurrentWeek: Bool
    let isCompleted: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行
            HStack {
                Text("Week \(weekNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已完成")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else if isCurrentWeek {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.blue)
                        Text("进行中")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.gray)
                        Text("未开始")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // 进度点
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index < progress ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Group {
                                if index < progress {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .bold))
                                } else {
                                    Text("\(index + 1)")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 14))
                                }
                            }
                        )
                }
            }
            
            // 进度信息
            HStack {
                Text("\(progress)/6")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if retries > 0 {
                    Spacer()
                    Text("重试 \(retries) 次")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isCurrentWeek ? Color.blue : Color.clear, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 预览

#Preview {
    let context = PersistenceController.shared.container.viewContext
    
    // 创建测试数据
    let entity = NSEntityDescription.entity(forEntityName: "HabitFormationTask", in: context)!
    let task = NSManagedObject(entity: entity, insertInto: context)
    task.setValue(UUID(), forKey: "id")
    task.setValue(UUID(), forKey: "habitId")
    task.setValue("早起", forKey: "habitName")
    task.setValue(Date(), forKey: "startDate")
    task.setValue(Int16(2), forKey: "currentWeek")
    task.setValue(Int16(6), forKey: "week1Progress")
    task.setValue(Int16(4), forKey: "week2Progress")
    task.setValue(Int16(0), forKey: "week3Progress")
    task.setValue(Int16(0), forKey: "week1Retries")
    task.setValue(Int16(1), forKey: "week2Retries")
    task.setValue(Int16(0), forKey: "week3Retries")
    task.setValue("ongoing", forKey: "status")
    task.setValue(false, forKey: "isInMaintenance")
    
    return HabitFormationView(task: task)
}

