import SwiftUI
import Combine

private struct AdventureTaskPool: Decodable {
    let tasks: [AdventureTask]
}

private struct AdventureTask: Decodable, Identifiable {
    let id: String
    let type: String
    let category: String
    let title: String
    let defaultDurationMinutes: Int
    let successCriteria: String
    let source: String
    let enabled: Bool
}

struct AdventureRouletteView: View {
    @State private var allTasks = Self.loadTasks()
    @State private var wheelTasks: [AdventureTask] = []
    @State private var selectedTask: AdventureTask?
    @State private var flowTask: AdventureTask?
    @State private var rotationDegrees = 0.0
    @State private var isSpinning = false

    private let colors: [Color] = [
        Color(red: 0.99, green: 0.77, blue: 0.43),
        Color(red: 0.98, green: 0.57, blue: 0.52),
        Color(red: 0.65, green: 0.78, blue: 0.96),
        Color(red: 0.61, green: 0.83, blue: 0.72),
        Color(red: 0.80, green: 0.70, blue: 0.91),
        Color(red: 0.98, green: 0.68, blue: 0.72),
        Color(red: 0.62, green: 0.84, blue: 0.86),
        Color(red: 0.94, green: 0.84, blue: 0.55)
    ]

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("今天，抽一件小事开始")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
                Text("不用安排很多，完成一点点也很好")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            if allTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("任务池暂时无法读取")
                        .font(.headline)
                    Text("请确认任务数据文件已加入 Nopush App target。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                wheel

                Button(action: spin) {
                    Label(isSpinning ? "转盘正在转" : (selectedTask == nil ? "转一下" : "再转一次"),
                          systemImage: isSpinning ? "sparkles" : "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color(red: 0.96, green: 0.43, blue: 0.39)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(isSpinning)

                if let task = selectedTask {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("建议 \(task.defaultDurationMinutes) 分钟 · \(task.category)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer(minLength: 4)
                        Button("详情") {
                            flowTask = task
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .padding(14)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.green.opacity(0.18), lineWidth: 1)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .sheet(item: $flowTask) { task in
            AdventureTaskFlowSheet(task: task)
        }
        .onAppear {
            if wheelTasks.isEmpty {
                wheelTasks = Array(allTasks.shuffled().prefix(8))
            }
        }
    }

    private var wheel: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, 330)
            let count = max(wheelTasks.count, 1)

            ZStack {
                ForEach(Array(wheelTasks.enumerated()), id: \.element.id) { entry in
                    let index = entry.offset
                    let task = entry.element
                    let midAngle = (-90.0 + (Double(index) + 0.5) * 360.0 / Double(count)) * .pi / 180.0
                    let labelX = side / 2 + CGFloat(cos(midAngle)) * side * 0.30
                    let labelY = side / 2 + CGFloat(sin(midAngle)) * side * 0.30

                    WheelSlice(index: index, count: count)
                        .fill(colors[index % colors.count])
                        .overlay(
                            WheelSlice(index: index, count: count)
                                .stroke(Color.white.opacity(0.85), lineWidth: 2)
                        )

                    Text(String(task.title.prefix(10)))
                        .font(.system(size: 9, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .foregroundColor(Color.black.opacity(0.82))
                        .frame(width: side * 0.22)
                        .position(x: labelX, y: labelY)
                }

                Circle()
                    .fill(Color.white)
                    .frame(width: side * 0.20, height: side * 0.20)
                    .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
                Image(systemName: "sparkles")
                    .font(.system(size: side * 0.075, weight: .bold))
                    .foregroundColor(.orange)
            }
            .frame(width: side, height: side)
            .rotationEffect(.degrees(rotationDegrees))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.93, green: 0.39, blue: 0.35))
                    .rotationEffect(.degrees(180))
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                    .offset(y: -4)
            }
        }
        .frame(height: 310)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("八项随机任务转盘")
    }

    private func spin() {
        guard allTasks.count > 0, !isSpinning else { return }

        let nextWheelTasks = Array(allTasks.shuffled().prefix(8))
        let count = nextWheelTasks.count
        guard count > 0 else { return }
        let winningIndex = Int.random(in: 0..<count)
        let duration = 3.0
        let targetRotation = 5 * 360.0 - (Double(winningIndex) + 0.5) * 360.0 / Double(count)

        var resetTransaction = Transaction()
        resetTransaction.disablesAnimations = true
        withTransaction(resetTransaction) {
            wheelTasks = nextWheelTasks
            selectedTask = nil
            rotationDegrees = 0
            isSpinning = true
        }

        withAnimation(.easeOut(duration: duration)) {
            rotationDegrees = targetRotation
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            selectedTask = nextWheelTasks[winningIndex]
            isSpinning = false
        }
    }

    private static func loadTasks() -> [AdventureTask] {
        guard let url = Bundle.main.url(forResource: "home_boredom_100_tasks", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let pool = try? JSONDecoder().decode(AdventureTaskPool.self, from: data) else {
            return []
        }
        return pool.tasks.filter(\.enabled)
    }
}

private struct WheelSlice: Shape {
    let index: Int
    let count: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let slice = 360.0 / Double(count)
        let start = -90.0 + Double(index) * slice
        let end = start + slice

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(start),
            endAngle: .degrees(end),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

private struct AdventureTaskDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let task: AdventureTask

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(task.category)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.orange)
                Text(task.title)
                    .font(.title2.weight(.bold))
                Text(task.successCriteria)
                    .font(.body)
                    .foregroundColor(.secondary)
                Label("建议用时 \(task.defaultDurationMinutes) 分钟", systemImage: "clock")
                    .font(.subheadline.weight(.medium))
                    .padding(.top, 4)
                Spacer()
                Text("做到描述里的小目标就算完成，不需要做到完美。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(24)
            .navigationTitle("任务详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("知道了") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}


private struct AdventureTaskFlowSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("nopush.adventure.coins") private var coins = 5

    let task: AdventureTask

    @State private var stage: Stage = .setup
    @State private var minutes: Int
    @State private var customMinutes = ""
    @State private var elapsedBeforePause: TimeInterval = 0
    @State private var startedAt: Date?
    @State private var totalSeconds: TimeInterval = 0
    @State private var extensionUsed = false
    @State private var extensionPromptDismissed = false
    @State private var message: String?

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(task: AdventureTask) {
        self.task = task
        _minutes = State(initialValue: task.defaultDurationMinutes)
    }

    private enum Stage {
        case setup, ready, running, extension, success, failed
    }

    private var elapsed: TimeInterval {
        elapsedBeforePause + (startedAt.map { Date().timeIntervalSince($0) } ?? 0)
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return min(1, elapsed / totalSeconds)
    }

    private var remaining: TimeInterval {
        max(0, totalSeconds - elapsed)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    switch stage {
                    case .setup:
                        setupContent
                    case .ready:
                        readyContent
                    case .running:
                        runningContent
                    case .extensionPrompt:
                        extensionContent
                    case .success:
                        successContent
                    case .failed:
                        failedContent
                    }
                }
                .padding(20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(stageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(stage == .running || stage == .extensionPrompt ? "结束" : "关闭") {
                        if stage == .running || stage == .extensionPrompt {
                            stopAsFailed()
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .onReceive(ticker) { date in
                tick(at: date)
            }
            .alert("金币充值", isPresented: Binding(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )) {
                Button("知道了", role: .cancel) { message = nil }
            } message: {
                Text(message ?? "")
            }
        }
        .presentationDetents([.large])
    }

    private var stageTitle: String {
        switch stage {
        case .setup: return "准备冒险"
        case .ready: return "准备开始"
        case .running: return "正在冒险"
        case .extensionPrompt: return "要继续吗？"
        case .success: return "冒险完成"
        case .failed: return "本次结束"
        }
    }

    private var setupContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            taskHeader
            Text("你愿意给这件小事多少时间？")
                .font(.headline)
            HStack(spacing: 8) {
                ForEach([5, 10, 20, 30], id: \.self) { value in
                    Button("\(value) 分钟") { minutes = value }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(minutes == value ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(minutes == value ? Color.orange : Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            HStack {
                Text("自定义")
                    .foregroundColor(.secondary)
                TextField("分钟", text: $customMinutes)
                    .keyboardType(.numberPad)
                    .frame(width: 75)
                    .textFieldStyle(.roundedBorder)
                Text("分钟")
                    .foregroundColor(.secondary)
                Spacer()
            }
            Text("现在只是在做准备，计时还没有开始。")
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            actionButton("加入今日冒险", icon: "checkmark") {
                if let custom = Int(customMinutes), custom > 0 {
                    minutes = min(custom, 180)
                }
                totalSeconds = TimeInterval(minutes * 60)
                stage = .ready
            }
        }
    }

    private var readyContent: some View {
        VStack(spacing: 18) {
            taskHeader
            timerFace(progress: 0, time: "00:00", caption: "尚未开始")
            Text("给自己 \(minutes) 分钟。准备好再开始。")
                .foregroundColor(.secondary)
            actionButton("开始计时", icon: "play.fill") {
                elapsedBeforePause = 0
                startedAt = Date()
                extensionUsed = false
                extensionPromptDismissed = false
                stage = .running
            }
            Button("修改任务时间") { stage = .setup }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
        }
    }

    private var runningContent: some View {
        VStack(spacing: 18) {
            taskHeader
            timerFace(progress: progress, time: formatted(remaining), caption: "剩余时间")
            Text(extensionUsed ? "延时包已使用" : "到达自设时长的 80% 时可选择是否延时")
                .font(.footnote)
                .foregroundColor(.secondary)
            actionButton("我完成了", icon: "checkmark") {
                stage = .success
                startedAt = nil
            }
            Button("这次先结束") { stopAsFailed() }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            #if DEBUG
            Button("演示：跳到 80% 节点") {
                elapsedBeforePause = totalSeconds * 0.8
                startedAt = nil
                stage = .extensionPrompt
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            #endif
        }
    }

    private var extensionContent: some View {
        VStack(spacing: 18) {
            taskHeader
            timerFace(
                progress: 0.8,
                time: formatted(max(0, totalSeconds - elapsedBeforePause)),
                caption: "已用 \(Int(Double(minutes) * 0.8)) / \(minutes) 分钟"
            )
            Text("还差一点点，要继续吗？延时是可选的。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            actionButton("试用延时包 · +15 分钟", icon: "plus.circle.fill") {
                extensionUsed = true
                totalSeconds += 15 * 60
                startedAt = Date()
                stage = .running
            }
            Text("延时包价格与支付方式尚未设定；此原型不会扣款。")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("按原计划继续") {
                extensionPromptDismissed = true
                startedAt = Date()
                stage = .running
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
    }

    private var successContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(.mint)
            Text("这件小事，你做到了。")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(task.title)
                .foregroundColor(.secondary)
            Text("完成一小步，也值得被记下来。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            actionButton("回到冒险转盘", icon: "sparkles") { dismiss() }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    private var failedContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "arrow.counterclockwise.circle.fill")
                .font(.system(size: 62))
                .foregroundColor(.orange)
            Text("这次还没完成")
                .font(.title2.bold())
            Text("没关系，准备好时可以再来一次。")
                .foregroundColor(.secondary)
            taskHeader
            if coins > 0 {
                Text("本周还有 \(coins) 枚金币。使用 1 枚购买一次重来机会。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                actionButton("用 1 枚金币买一次重来机会", icon: "arrow.clockwise") {
                    coins -= 1
                    elapsedBeforePause = 0
                    totalSeconds = TimeInterval(minutes * 60)
                    extensionUsed = false
                    extensionPromptDismissed = false
                    startedAt = nil
                    stage = .ready
                }
            } else {
                Text("本周金币用完了。可以充值，或清零并重新开始。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                actionButton("充值金币（演示）", icon: "plus.circle") {
                    message = "正式支付尚未接入。本原型不会扣款或发起支付。"
                }
                Button("清零并重新开始") {
                    coins = 5
                    elapsedBeforePause = 0
                    totalSeconds = TimeInterval(minutes * 60)
                    stage = .ready
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            Button("先休息一下") { dismiss() }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
    }

    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(task.category)
                .font(.caption.weight(.bold))
                .foregroundColor(.teal)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.teal.opacity(0.12))
                .clipShape(Capsule())
            Text(task.title)
                .font(.title3.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            Text(task.successCriteria)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if stage == .running || stage == .extensionPrompt {
                Text("你设定的时间：\(minutes) 分钟")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func timerFace(progress: Double, time: String, caption: String) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.13), lineWidth: 13)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 13, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 5) {
                Text(time)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 205, height: 205)
        .padding(.vertical, 8)
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color(red: 0.96, green: 0.43, blue: 0.39)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func tick(at date: Date) {
        guard stage == .running else { return }
        let currentElapsed = elapsedBeforePause + (startedAt.map { date.timeIntervalSince($0) } ?? 0)

        if !extensionUsed && !extensionPromptDismissed && currentElapsed >= totalSeconds * 0.8 {
            elapsedBeforePause = totalSeconds * 0.8
            startedAt = nil
            stage = .extensionPrompt
        } else if currentElapsed >= totalSeconds {
            elapsedBeforePause = totalSeconds
            startedAt = nil
            stage = .failed
        }
    }

    private func stopAsFailed() {
        elapsedBeforePause = min(totalSeconds, elapsed)
        startedAt = nil
        stage = .failed
    }

    private func formatted(_ seconds: TimeInterval) -> String {
        let value = max(0, Int(seconds.rounded(.up)))
        return String(format: "%02d:%02d", value / 60, value % 60)
    }
}
