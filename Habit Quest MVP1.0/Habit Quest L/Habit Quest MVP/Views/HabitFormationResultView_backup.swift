import SwiftUI

/// 21天挑战结果视图（成功/失败）
struct HabitFormationResultView: View {
    let isSuccess: Bool
    let habitName: String
    let taskData: HabitFormationTaskData?
    @Environment(\.dismiss) var dismiss
    @State private var showConfetti = false
    
    struct HabitFormationTaskData {
        let totalDays: Int
        let totalEXP: Int
        let attributeGrowth: [String: Int]
        let completionRate: Double
        let failedWeek: Int?
    }
    
    var body: some View {
        ZStack {
            // 背景
            (isSuccess ? Color.green : Color.red)
                .opacity(0.1)
                .ignoresSafeArea()
            
            // 五彩纸屑动画（仅成功时）
            if isSuccess && showConfetti {
                ConfettiView()
            }
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)
                    
                    // 标题区
                    titleSection
                    
                    // 数据回顾
                    if let data = taskData {
                        dataReviewSection(data: data)
                    }
                    
                    // 激励/鼓励文案
                    motivationSection
                    
                    // 按钮区
                    buttonSection
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .onAppear {
            if isSuccess {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfetti = true
                    // 触觉反馈
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }
    
    // MARK: - 标题区
    
    private var titleSection: some View {
        VStack(spacing: 20) {
            // 图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isSuccess ? [Color.green, Color.blue] : [Color.red, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: (isSuccess ? Color.green : Color.red).opacity(0.4), radius: 20, x: 0, y: 10)
                
                Text(isSuccess ? "🎉" : "💔")
                    .font(.system(size: 60))
            }
            
            // 标题
            Text(isSuccess ? "挑战成功！" : "挑战失败")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(isSuccess ? .green : .red)
            
            // 习惯名称
            Text(habitName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // 副标题
            Text(isSuccess ? "恭喜你完成了21天挑战！" : "这次没有成功，但不要气馁")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - 数据回顾
    
    private func dataReviewSection(data: HabitFormationTaskData) -> some View {
        VStack(spacing: 16) {
            Text("数据回顾")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                if isSuccess {
                    // 成功数据
                    DataRow(
                        icon: "calendar.badge.clock",
                        iconColor: .blue,
                        title: "坚持天数",
                        value: "\(data.totalDays) 天"
                    )
                    
                    DataRow(
                        icon: "bolt.fill",
                        iconColor: .orange,
                        title: "获得经验",
                        value: "+\(data.totalEXP) EXP"
                    )
                    
                    DataRow(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .green,
                        title: "完成率",
                        value: "\(Int(data.completionRate * 100))%"
                    )
                    
                    // 四维属性增长
                    if !data.attributeGrowth.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "star.circle.fill")
                                    .foregroundColor(.purple)
                                Text("属性增长")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.top, 8)
                            
                            ForEach(Array(data.attributeGrowth.keys.sorted()), id: \.self) { key in
                                if let value = data.attributeGrowth[key], value > 0 {
                                    HStack {
                                        Text(key)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("+\(value)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple.opacity(0.1))
                        )
                    }
                } else {
                    // 失败数据
                    if let failedWeek = data.failedWeek {
                        DataRow(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .orange,
                            title: "失败于",
                            value: "第 \(failedWeek) 周"
                        )
                    }
                    
                    DataRow(
                        icon: "calendar",
                        iconColor: .blue,
                        title: "已坚持",
                        value: "\(data.totalDays) 天"
                    )
                    
                    DataRow(
                        icon: "chart.bar.fill",
                        iconColor: .green,
                        title: "完成率",
                        value: "\(Int(data.completionRate * 100))%"
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
        }
    }
    
    // MARK: - 激励文案
    
    private var motivationSection: some View {
        VStack(spacing: 12) {
            Image(systemName: isSuccess ? "hand.thumbsup.fill" : "heart.fill")
                .font(.title)
                .foregroundColor(isSuccess ? .yellow : .pink)
            
            Text(getMotivationText())
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill((isSuccess ? Color.yellow : Color.pink).opacity(0.1))
        )
    }
    
    private func getMotivationText() -> String {
        if isSuccess {
            return """
            太棒了！你成功完成了21天挑战，这个习惯已经深深刻在你的生活中。
            现在进入维持模式，继续保持每周5/6的目标，每周达标可获得 +50 EXP 奖励！
            """
        } else {
            return """
            养成习惯从来都不是一件容易的事，这次的失败只是暂时的。
            分析一下失败的原因，调整策略，重新开始。相信自己，你一定可以做到！
            """
        }
    }
    
    // MARK: - 按钮区
    
    private var buttonSection: some View {
        VStack(spacing: 12) {
            if isSuccess {
                Button(action: {
                    dismiss()
                }) {
                    Text("太棒了！")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
            } else {
                Button(action: {
                    // TODO: 重新开始挑战
                    dismiss()
                }) {
                    Text("重新开始")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("返回")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - 数据行

struct DataRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 32)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 五彩纸屑动画

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50) { index in
                Circle()
                    .fill(randomColor())
                    .frame(width: CGFloat.random(in: 5...15), height: CGFloat.random(in: 5...15))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: animate ? UIScreen.main.bounds.height + 100 : -100
                    )
                    .animation(
                        Animation.linear(duration: Double.random(in: 2...4))
                            .delay(Double.random(in: 0...0.5))
                            .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
        .allowsHitTesting(false)
    }
    
    private func randomColor() -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        return colors.randomElement() ?? .blue
    }
}

// MARK: - 预览

#Preview("成功") {
    HabitFormationResultView(
        isSuccess: true,
        habitName: "早起",
        taskData: HabitFormationResultView.HabitFormationTaskData(
            totalDays: 21,
            totalEXP: 630,
            attributeGrowth: [
                "力量": 15,
                "智慧": 10,
                "敏捷": 8,
                "魅力": 12
            ],
            completionRate: 0.95,
            failedWeek: nil
        )
    )
}

#Preview("失败") {
    HabitFormationResultView(
        isSuccess: false,
        habitName: "早起",
        taskData: HabitFormationResultView.HabitFormationTaskData(
            totalDays: 12,
            totalEXP: 240,
            attributeGrowth: [:],
            completionRate: 0.67,
            failedWeek: 2
        )
    )
}

