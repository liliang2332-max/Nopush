
import Foundation
import CoreData

class HabitFormationManager {
    private let context: NSManagedObjectContext
    
    var currentFormationTask: HabitFormationTask?
    var weekProgress: [Bool] = Array(repeating: false, count: 6)
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadCurrentTask()
    }
    
    // MARK: - 加载当前任务
    private func loadCurrentTask() {
        let request: NSFetchRequest<HabitFormationTask> = HabitFormationTask.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "ongoing")
        
        do {
            let tasks = try context.fetch(request)
            currentFormationTask = tasks.first
            updateWeekProgress()
        } catch {
            print("❌ 加载习惯养成任务失败: \(error)")
        }
    }
    
    // MARK: - 创建21天挑战
    func createFormationTask(habitId: UUID, habitName: String) -> Bool {
        if currentFormationTask != nil {
            print("⚠️ 已有一个习惯养成任务正在进行")
            return false
        }
        
        let task = HabitFormationTask(context: context)
        task.id = UUID()
        task.habitId = habitId
        task.habitName = habitName
        task.startDate = Date()
        task.currentWeek = 1
        task.week1Progress = 0
        task.week2Progress = 0
        task.week3Progress = 0
        task.week1Retries = 0
        task.week2Retries = 0
        task.week3Retries = 0
        task.status = "ongoing"
        task.isInMaintenance = false
        task.createdDate = Date()
        
        do {
            try context.save()
            currentFormationTask = task
            updateWeekProgress()
            print("✅ 习惯养成任务创建成功: \(habitName)")
            return true
        } catch {
            print("❌ 创建习惯养成任务失败: \(error)")
            return false
        }
    }
    
    // MARK: - 记录每日完成
    func recordDailyCompletion() -> Bool {
        guard let task = currentFormationTask else {
            print("⚠️ 没有进行中的习惯养成任务")
            return false
        }
        
        if let lastDate = task.lastCompletedDate,
           Calendar.current.isDateInToday(lastDate) {
            print("⚠️ 今天已经完成过了")
            return false
        }
        
        switch task.currentWeek {
        case 1:
            task.week1Progress += 1
        case 2:
            task.week2Progress += 1
        case 3:
            task.week3Progress += 1
        default:
            break
        }
        
        task.lastCompletedDate = Date()
        
        do {
            try context.save()
            updateWeekProgress()
            
            let currentProgress = getCurrentWeekProgress()
            if currentProgress >= 6 {
                checkWeeklyGoal()
            }
            
            print("✅ 记录完成，本周进度: \(currentProgress)/6")
            return true
        } catch {
            print("❌ 记录失败: \(error)")
            return false
        }
    }
    
    // MARK: - 检查每周目标
    func checkWeeklyGoal() {
        guard let task = currentFormationTask else { return }
        
        let currentProgress = getCurrentWeekProgress()
        
        if currentProgress >= 5 {
            handleWeekSuccess()
        } else {
            print("⚠️ 本周进度: \(currentProgress)/6，需要至少5天")
        }
    }
    
    func checkWeekEnd() {
        guard let task = currentFormationTask else { return }
        
        let currentProgress = getCurrentWeekProgress()
        
        if currentProgress >= 5 {
            handleWeekSuccess()
        } else {
            handleWeekFailure()
        }
    }
    
    // MARK: - 处理本周成功
    private func handleWeekSuccess() {
        guard let task = currentFormationTask else { return }
        
        print("🎉 Week \(task.currentWeek) 达标！(\(getCurrentWeekProgress())/6)")
        
        if task.currentWeek < 3 {
            moveToNextWeek()
        } else {
            completeChallenge()
        }
    }
    
    // MARK: - 处理本周失败
    private func handleWeekFailure() {
        guard let task = currentFormationTask else { return }
        
        let currentWeek = task.currentWeek
        let currentProgress = getCurrentWeekProgress()
        
        print("❌ Week \(currentWeek) 未达标：\(currentProgress)/6")
        
        let retries = getCurrentWeekRetries()
        
        if retries < 2 {
            incrementRetries()
            resetCurrentWeek()
            print("🔄 重试 Week \(currentWeek)（第 \(retries + 1) 次重试）")
        } else {
            failChallenge()
        }
    }
    
    // MARK: - 进入下一周
    private func moveToNextWeek() {
        guard let task = currentFormationTask else { return }
        
        task.currentWeek += 1
        
        do {
            try context.save()
            updateWeekProgress()
            print("➡️ 进入 Week \(task.currentWeek)")
        } catch {
            print("❌ 进入下一周失败: \(error)")
        }
    }
    
    // MARK: - 完成21天挑战
    func completeChallenge() {
        guard let task = currentFormationTask else { return }
        
        task.status = "completed"
        task.isInMaintenance = true
        
        do {
            try context.save()
            print("🎊 21天挑战完成！进入维持模式")
            
            NotificationCenter.default.post(
                name: NSNotification.Name("HabitFormationCompleted"),
                object: task.habitName
            )
            
        } catch {
            print("❌ 完成挑战失败: \(error)")
        }
    }
    
    // MARK: - 挑战失败
    private func failChallenge() {
        guard let task = currentFormationTask else { return }
        
        task.status = "failed"
        
        do {
            try context.save()
            currentFormationTask = nil
            print("💔 21天挑战失败")
            
            NotificationCenter.default.post(
                name: NSNotification.Name("HabitFormationFailed"),
                object: task.habitName
            )
            
        } catch {
            print("❌ 失败处理错误: \(error)")
        }
    }
    
    // MARK: - 辅助方法
    
    private func getCurrentWeekProgress() -> Int16 {
        guard let task = currentFormationTask else { return 0 }
        
        switch task.currentWeek {
        case 1: return task.week1Progress
        case 2: return task.week2Progress
        case 3: return task.week3Progress
        default: return 0
        }
    }
    
    private func getCurrentWeekRetries() -> Int16 {
        guard let task = currentFormationTask else { return 0 }
        
        switch task.currentWeek {
        case 1: return task.week1Retries
        case 2: return task.week2Retries
        case 3: return task.week3Retries
        default: return 0
        }
    }
    
    private func incrementRetries() {
        guard let task = currentFormationTask else { return }
        
        switch task.currentWeek {
        case 1: task.week1Retries += 1
        case 2: task.week2Retries += 1
        case 3: task.week3Retries += 1
        default: break
        }
        
        do {
            try context.save()
        } catch {
            print("❌ 增加重试次数失败: \(error)")
        }
    }
    
    private func resetCurrentWeek() {
        guard let task = currentFormationTask else { return }
        
        switch task.currentWeek {
        case 1: task.week1Progress = 0
        case 2: task.week2Progress = 0
        case 3: task.week3Progress = 0
        default: break
        }
        
        do {
            try context.save()
            updateWeekProgress()
        } catch {
            print("❌ 重置本周进度失败: \(error)")
        }
    }
    
    private func updateWeekProgress() {
        guard let task = currentFormationTask else {
            weekProgress = Array(repeating: false, count: 6)
            return
        }
        
        let progress = getCurrentWeekProgress()
        weekProgress = (0..<6).map { $0 < progress }
    }
    
    // MARK: - 维持模式检查
    func checkMaintenanceWeek() {
        guard let task = currentFormationTask,
              task.isInMaintenance else { return }
        
        let currentProgress = getCurrentWeekProgress()
        
        if currentProgress >= 5 {
            print("✅ 维持模式：本周达标")
            NotificationCenter.default.post(
                name: NSNotification.Name("MaintenanceWeekCompleted"),
                object: nil
            )
        } else {
            print("⚠️ 维持模式：本周未达标，但不会失败")
        }
        
        resetCurrentWeek()
    }
    
    // MARK: - 查询方法
    
    func canCreateNewFormation() -> Bool {
        return currentFormationTask == nil
    }
    
    func getFormationStatus() -> String {
        guard let task = currentFormationTask else {
            return "无进行中的挑战"
        }
        
        let progress = getCurrentWeekProgress()
        let retries = getCurrentWeekRetries()
        
        if task.isInMaintenance {
            return "维持模式 - 本周 \(progress)/6"
        } else {
            return "Week \(task.currentWeek)/3 - 本周 \(progress)/6（重试:\(retries)/2）"
        }
    }
    // MARK: - 查询所有进行中的任务
    func getAllOngoingFormationTasks() -> [HabitFormationTask] {
        let request: NSFetchRequest<HabitFormationTask> = HabitFormationTask.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "ongoing")
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ 查询失败: \(error)")
            return []
        }
    }

}


