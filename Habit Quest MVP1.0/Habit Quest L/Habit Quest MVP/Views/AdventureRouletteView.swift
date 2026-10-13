import SwiftUI

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
    @State private var detailTask: AdventureTask?
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
                            detailTask = task
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
        .sheet(item: $detailTask) { task in
            AdventureTaskDetailSheet(task: task)
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
