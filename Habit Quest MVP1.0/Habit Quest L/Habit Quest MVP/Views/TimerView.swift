import SwiftUI
import CoreData

// 计时器主界面
struct TimerView: View {
    let habit: NSManagedObject
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var expViewModel: ExperienceViewModel
    
    @StateObject private var timerVM: TimerViewModel
    
    init(habit: NSManagedObject) {
        self.habit = habit
        _timerVM = StateObject(wrappedValue: TimerViewModel(
            habit: habit,
            context: PersistenceController.shared.container.viewContext
        ))
    }
    
    var attributeColor: Color {
        if let typeString = habit.value(forKey: "attributeType") as? String,
           let type = AttributeType(rawValue: typeString) {
            return type.color
        }
        return .blue
    }
    
    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    var body: some View {
        let timeCoins = timerVM.getCurrentTimeCoins()
        
        ZStack {
            LinearGradient(
                colors: [Color(UIColor.systemBackground), attributeColor.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text(habit.value(forKey: "name") as? String ?? "未命名习惯")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let minutes = habit.value(forKey: "estimatedMinutes") as? Int16 {
                        Text("预计 \(minutes) 分钟")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 40)
                
                Spacer()
                
                RatingBadge(rating: timerVM.currentRating, size: .medium)
                
                VStack(spacing: 16) {
                    Text(formatTime(timerVM.elapsedSeconds))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(timerVM.progressColor)
                    
                    // ✅ 新增：暂停状态显示
                    if timerVM.state == .paused {
                        VStack(spacing: 8) {
                            Text("⏸️ 已暂停")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            let minutes = timerVM.pauseRemainingSeconds / 60
                            let seconds = timerVM.pauseRemainingSeconds % 60
                            
                            Text(String(format: "剩余 %02d:%02d", minutes, seconds))
                                .font(.subheadline)
                                .foregroundColor(timerVM.pauseRemainingSeconds < 60 ? .red : .secondary)
                            
                            if timerVM.pauseRemainingSeconds < 60 {
                                Text("⚠️ 即将超时失败")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    Text("\(timerVM.progressPercentage)%")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    if timerVM.elapsedSeconds < timerVM.estimatedSeconds {
                        let remainingSeconds = timerVM.estimatedSeconds - timerVM.elapsedSeconds
                        let remainingMinutes = (remainingSeconds + 59) / 60
                        Text("还剩 \(remainingMinutes) 分钟")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    } else {
                        let overtimeSeconds = timerVM.elapsedSeconds - timerVM.estimatedSeconds
                        let overtimeMinutes = overtimeSeconds / 60
                        Text("已超时 \(overtimeMinutes) 分钟")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    
                    ProgressBar(progress: timerVM.progress, color: timerVM.progressColor)
                        .frame(height: 20)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    if timerVM.canPurchaseDelay {
                        Button {
                            timerVM.showDelayPackageSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("购买延时包")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: timerVM.canPurchaseDelay)
                    }
                    
                    // ✅ 修改：按钮区域
                    HStack(spacing: 20) {
                        if timerVM.state == .idle {
                            // 开始按钮
                            Button {
                                timerVM.start()
                            } label: {
                                Text("开始")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(attributeColor)
                                    .cornerRadius(16)
                            }
                        } else if timerVM.state == .paused {
                            // ✅ 暂停状态的按钮
                            Button {
                                timerVM.resume()
                            } label: {
                                Label("恢复", systemImage: "play.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.green)
                                    .cornerRadius(16)
                            }
                            
                            // ✅ 时间币菜单
                            Menu {
                                Button {
                                    timerVM.extendPause()
                                } label: {
                                    Label("延长暂停 30分钟", systemImage: "clock")
                                    Text("需要 1 时间币")
                                }
                                .disabled(timerVM.getCurrentTimeCoins() < 1)
                                
                                Button {
                                    timerVM.saveProgressAndEnd()
                                } label: {
                                    Label("保存进度并结束", systemImage: "square.and.arrow.down")
                                    Text("需要 2 时间币")
                                }
                                .disabled(timerVM.getCurrentTimeCoins() < 2)
                                
                                Divider()
                                
                                Button {
                                    timerVM.adjustTaskWithTimeCoin()
                                } label: {
                                    Label("获取AI建议", systemImage: "brain")
                                    Text("需要 3 时间币")
                                }
                                .disabled(timerVM.getCurrentTimeCoins() < 3)
                                
                            } label: {
                                Label("时间币 (\(timeCoins))", systemImage: "bitcoinsign.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.orange)
                                    .cornerRadius(16)
                            }
                            
                        } else if timerVM.state == .running {
                            // 暂停按钮
                            Button {
                                timerVM.pause()
                            } label: {
                                Label("暂停", systemImage: "pause.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.orange)
                                    .cornerRadius(16)
                            }
                            
                            // 完成按钮
                            Button {
                                timerVM.complete()
                            } label: {
                                Text("完成")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.blue)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("\(timeCoins)")
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
        .sheet(isPresented: $timerVM.showDelayPackageSheet) {
            DelayPackageSheet(
                timerVM: timerVM,
                currentEXP: expViewModel.currentEXP,
                habit: habit,
                onPurchase: { timerVM.purchaseDelayPackage(currentEXP: expViewModel.currentEXP) }
            )
        }
        .sheet(isPresented: $timerVM.showCompletionSheet) {
            CompletionView(
                rating: timerVM.currentRating,
                habit: habit,
                badge: timerVM.earnedBadge,
                onDismiss: { dismiss() }
            )
        }
        .sheet(isPresented: $timerVM.showFailureSheet) {
            FailureView(
                habit: habit,
                onDismiss: { dismiss() }
            )
        }
        .sheet(isPresented: $timerVM.showTimeCoinSheet) {
            TimeCoinActionSheet(
                timerVM: timerVM,
                currentTimeCoins: timeCoins,
                onPause: { timerVM.pauseTaskWithTimeCoin() },
                onAdjust: { timerVM.adjustTaskWithTimeCoin() }
            )
        }
        .sheet(isPresented: $timerVM.showAdjustmentSheet) {
            TaskAdjustmentSheet(
                habit: habit,
                currentProgress: timerVM.progressPercentage,
                elapsedSeconds: timerVM.elapsedSeconds
            )
        }
        .alert("错误", isPresented: .constant(timerVM.errorMessage != nil)) {
            Button("确定") { timerVM.errorMessage = nil }
        } message: {
            if let error = timerVM.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - 子组件

struct ProgressBar: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(min(progress, 1.0)))
                    .cornerRadius(10)
                    .animation(.linear(duration: 1), value: progress)
            }
        }
    }
}

struct RatingBadge: View {
    let rating: RatingType
    let size: BadgeSize
    
    enum BadgeSize {
        case small, medium, large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 32
            case .large: return 48
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 16
            case .large: return 24
            }
        }
    }
    
    var body: some View {
        Text(rating.rawValue)
            .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(size.padding)
            .background(
                Circle()
                    .fill(rating.color)
                    .shadow(color: rating.color.opacity(0.5), radius: 8, x: 0, y: 4)
            )
    }
}

struct DelayPackageSheet: View {
    @ObservedObject var timerVM: TimerViewModel
    let currentEXP: Int
    let habit: NSManagedObject
    let onPurchase: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let delayManager = DelayPackageManager(context: PersistenceController.shared.container.viewContext)
    
    var cost: Int {
        delayManager.calculatePrice(for: habit)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("需要更多时间吗?")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                VStack {
                    Text("当前评价")
                        .font(.caption)
                    RatingBadge(rating: timerVM.currentRating, size: .medium)
                }
                
                Image(systemName: "arrow.right")
                    .font(.title2)
                
                VStack {
                    Text("使用后")
                        .font(.caption)
                    RatingBadge(rating: timerVM.currentRating.downgrade(), size: .medium)
                        .opacity(0.6)
                }
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("所需经验值")
                    Spacer()
                    Text("\(cost) EXP")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("当前拥有")
                    Spacer()
                    Text("\(currentEXP) EXP")
                        .fontWeight(.bold)
                        .foregroundColor(currentEXP >= cost ? .green : .red)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            
            Text("延长 15 分钟")
                .font(.headline)
                .foregroundColor(.orange)
            
            Text("使用延时包将降低任务评价")
                .font(.caption)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("确认购买") {
                    onPurchase()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(currentEXP < cost)
            }
        }
        .padding(32)
    }
}

struct CompletionView: View {
    let rating: RatingType
    let habit: NSManagedObject
    let badge: BadgeType?
    let onDismiss: () -> Void
    
    private let ratingManager = RatingManager()
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            RatingBadge(rating: rating, size: .large)
                .scaleEffect(1.2)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: rating)
            
            let info = ratingManager.getRatingInfo(rating: rating)
            
            Text(info.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(info.message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let badge = badge {
                HStack(spacing: 12) {
                    Text(badge.icon)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(badge.rawValue)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(badge.color)
                        
                        Text(badge.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(badge.color.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(badge.color, lineWidth: 2)
                )
            }
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("+\(rating.expReward) EXP")
                        .fontWeight(.bold)
                }
                
                if let typeString = habit.value(forKey: "attributeType") as? String,
                   let type = AttributeType(rawValue: typeString) {
                    HStack {
                        Text(type.icon)
                        Text("+\(ratingManager.calculateAttributePoints(rating: rating)) \(type.rawValue)")
                            .fontWeight(.bold)
                    }
                }
            }
            .font(.title3)
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Text("太棒了!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(rating.color)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .interactiveDismissDisabled()
    }
}

struct FailureView: View {
    let habit: NSManagedObject
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.red)
                .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("任务失败")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("很遗憾，任务已超时")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                    Text("未获得经验值")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                    Text("未获得属性点")
                        .fontWeight(.bold)
                }
            }
            .font(.title3)
            .foregroundColor(.red)
            
            Text("提示: 下次可以在80%进度时购买延时包")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Text("知道了")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .interactiveDismissDisabled()
    }
}

struct TimeCoinActionSheet: View {
    @ObservedObject var timerVM: TimerViewModel
    @Environment(\.dismiss) private var dismiss
    
    let currentTimeCoins: Int
    let onPause: () -> Void
    let onAdjust: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("需要帮助吗?")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text("剩余时间币: \(currentTimeCoins)")
                    .font(.headline)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.blue)
                    Text("保存进度并结束")
                        .font(.headline)
                    Spacer()
                    Text("2 时间币")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("任务会立即结束，你将获得当前进度的经验值和勋章")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    onPause()
                    dismiss()
                } label: {
                    Text("保存进度")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(currentTimeCoins >= 2 ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(currentTimeCoins < 2)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.green)
                    Text("调整任务")
                        .font(.headline)
                    Spacer()
                    Text("3 时间币")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("获取AI分析和优化建议，帮助你更好地完成任务")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    onAdjust()
                    dismiss()
                } label: {
                    Text("获取AI建议")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(currentTimeCoins >= 3 ? Color.green : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(currentTimeCoins < 3)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            
            Button("取消") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
    }
}

struct TaskAdjustmentSheet: View {
    let habit: NSManagedObject
    let currentProgress: Int
    let elapsedSeconds: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                Text("AI 任务分析")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("当前状态")
                    .font(.headline)
                
                HStack {
                    Text("预估时间:")
                        .foregroundColor(.secondary)
                    Spacer()
                    if let minutes = habit.value(forKey: "estimatedMinutes") as? Int16 {
                        Text("\(minutes) 分钟")
                            .fontWeight(.bold)
                    }
                }
                
                HStack {
                    Text("已用时间:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(elapsedSeconds / 60) 分钟")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("当前进度:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(currentProgress)%")
                        .fontWeight(.bold)
                        .foregroundColor(currentProgress >= 80 ? .red : .orange)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.green)
                    Text("优化建议")
                        .font(.headline)
                }
                
                if currentProgress >= 80 {
                    Text("你的实际完成时间可能超出预估。建议:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("将任务时间调整为更合理的时长", systemImage: "1.circle.fill")
                        Label("或将任务拆分为更小的步骤", systemImage: "2.circle.fill")
                        Label("下次开始前做好充分准备", systemImage: "3.circle.fill")
                    }
                    .font(.subheadline)
                } else {
                    Text("你的进度良好!建议:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("保持当前节奏继续完成", systemImage: "1.circle.fill")
                        Label("注意时间管理，避免干扰", systemImage: "2.circle.fill")
                    }
                    .font(.subheadline)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("知道了")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .padding(32)
    }
}
