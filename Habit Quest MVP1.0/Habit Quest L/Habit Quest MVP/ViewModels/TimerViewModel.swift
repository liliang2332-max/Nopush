import Foundation
import Combine
import CoreData
import SwiftUI

// 计时器ViewModel
class TimerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var elapsedSeconds: Int = 0
    @Published var state: TimerState = .idle
    @Published var currentRating: RatingType = .s
    @Published var showDelayPackageSheet = false
    @Published var showCompletionSheet = false
    @Published var showFailureSheet = false
    @Published var errorMessage: String?
    @Published var earnedBadge: BadgeType? = nil
    @Published var showAdjustmentSheet = false
    @Published var showTimeCoinSheet = false
    @Published var pauseRemainingSeconds: Int = 300  // ✅ 新增：暂停倒计时（5分钟）
    
    // MARK: - Properties
    let habit: NSManagedObject
    private var cancellable: AnyCancellable?
    private var pauseTimer: AnyCancellable?  // ✅ 新增：暂停倒计时器
    private var startTime: Date?
    private var pausedTime: Date?
    private var totalPausedSeconds: Int = 0
    private var delayPackagesUsed: Int = 0
    private var extendedMinutes: Int = 0
    private var usedDelayPackage: Bool = false
    
    private let context: NSManagedObjectContext
    private let delayPackageManager: DelayPackageManager
    private let ratingManager = RatingManager()
    private let timeCoinManager: TimeCoinManager
    private let habitFormationManager: HabitFormationManager
    
    // MARK: - Computed Properties
    var estimatedSeconds: Int {
        let baseMinutes = habit.value(forKey: "estimatedMinutes") as? Int16 ?? 30
        return Int(baseMinutes) * 60 + extendedMinutes * 60
    }
    
    var progress: Double {
        guard estimatedSeconds > 0 else { return 0 }
        return min(Double(elapsedSeconds) / Double(estimatedSeconds), 1.0)
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var remainingMinutes: Int {
        max(0, (estimatedSeconds - elapsedSeconds) / 60)
    }
    
    var canPurchaseDelay: Bool {
        progress >= 0.8 && progress < 1.0 && currentRating.canPurchaseDelay
    }
    
    var progressColor: Color {
        if progress < 0.6 {
            return Color(red: 0.306, green: 0.804, blue: 0.769)
        } else if progress < 0.8 {
            return Color(red: 1.0, green: 0.722, blue: 0.302)
        } else {
            return Color(red: 1.0, green: 0.42, blue: 0.42)
        }
    }
    
    // MARK: - Initialization
    init(habit: NSManagedObject, context: NSManagedObjectContext) {
        self.habit = habit
        self.context = context
        self.delayPackageManager = DelayPackageManager(context: context)
        self.timeCoinManager = TimeCoinManager(context: context)
        self.habitFormationManager = HabitFormationManager(context: context)
        self.currentRating = .s
    }
    
    // MARK: - Cleanup
    deinit {
        cancellable?.cancel()
        pauseTimer?.cancel()  // ✅ 新增
        print("✅ TimerViewModel 已释放")
    }
    
    // MARK: - Timer Control
    func start() {
        guard state == .idle else { return }
        
        state = .running
        startTime = Date()
        
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    func pause() {
        guard state == .running else { return }
        
        state = .paused
        pausedTime = Date()
        pauseRemainingSeconds = 300  // ✅ 新增：重置为5分钟
        cancellable?.cancel()
        
        // ✅ 新增：开始暂停倒计时
        startPauseTimer()
    }
    
    func resume() {
        guard state == .paused, let pausedTime = pausedTime else { return }
        
        pauseTimer?.cancel()  // ✅ 新增：停止暂停倒计时
        
        let pauseDuration = Int(Date().timeIntervalSince(pausedTime))
        totalPausedSeconds += pauseDuration
        
        state = .running
        self.pausedTime = nil
        
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    func complete() {
        if elapsedSeconds > estimatedSeconds {
            fail()
            return
        }
        
        cancellable?.cancel()
        pauseTimer?.cancel()  // ✅ 新增：停止暂停倒计时
        state = .completed
        
        let actualMinutes = elapsedSeconds / 60
        let estimatedMinutes = Int(habit.value(forKey: "estimatedMinutes") as? Int16 ?? 30)
        
        if delayPackagesUsed == 0 {
            currentRating = ratingManager.calculateRating(
                estimatedMinutes: estimatedMinutes,
                actualMinutes: actualMinutes
            )
        }
        
        if !usedDelayPackage {
            earnedBadge = .purist
        } else {
            earnedBadge = .challenger
        }
        
        saveTaskRecord(wasOnTime: true)
        
        // 判断是否是习惯养成任务
        if isHabitFormationTask() {
            let success = habitFormationManager.recordDailyCompletion()
            if success {
                print("✅ 习惯养成任务完成记录成功")
            } else {
                print("⚠️ 习惯养成任务完成记录失败（可能今天已完成）")
            }
        }
        
        showCompletionSheet = true
    }
    
    func fail() {
        cancellable?.cancel()
        pauseTimer?.cancel()  // ✅ 新增：停止暂停倒计时
        state = .failed
        showFailureSheet = true
        print("❌ 任务失败：已超时")
    }
    
    private func tick() {
        elapsedSeconds += 1
        
        if elapsedSeconds > estimatedSeconds {
            fail()
            return
        }
        
        if delayPackagesUsed == 0 {
            let actualMinutes = elapsedSeconds / 60
            let estimatedMinutes = Int(habit.value(forKey: "estimatedMinutes") as? Int16 ?? 30)
            currentRating = ratingManager.calculateRating(
                estimatedMinutes: estimatedMinutes,
                actualMinutes: actualMinutes
            )
        }
    }
    
    // MARK: - Delay Package
    func purchaseDelayPackage(currentEXP: Int) {
        let result = delayPackageManager.purchaseDelayPackage(
            currentRating: currentRating,
            currentEXP: currentEXP,
            habit: habit
        )
        
        switch result {
        case .success(let (newRating, cost)):
            usedDelayPackage = true
            currentRating = newRating
            extendedMinutes += 15
            delayPackagesUsed += 1
            
            NotificationCenter.default.post(
                name: .expChanged,
                object: nil,
                userInfo: ["change": -cost]
            )
            
            showDelayPackageSheet = false
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Time Coin Actions
    
    func getCurrentTimeCoins() -> Int {
        return timeCoinManager.getCurrentTimeCoins()
    }
    
    func pauseTaskWithTimeCoin() {
        let result = timeCoinManager.pauseTask()
        
        switch result {
        case .success(let remaining):
            cancellable?.cancel()
            pauseTimer?.cancel()  // ✅ 停止暂停倒计时
            state = .paused
            
            // 日常任务：自动结束并给经验
            // 习惯养成任务：不计入当天进度
            if !isHabitFormationTask() {
                completeWithPartialProgress()
            } else {
                print("⚠️ 习惯养成任务已暂停（今日不计入进度）")
                showCompletionSheet = false
            }
            
            print("✅ 任务已暂停，剩余时间币：\(remaining)")
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    func adjustTaskWithTimeCoin() {
        let result = timeCoinManager.adjustTask()
        
        switch result {
        case .success(let remaining):
            showAdjustmentSheet = true
            print("✅ 获得AI调整建议，剩余时间币：\(remaining)")
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    // ✅ 新增方法1：开始暂停倒计时
    private func startPauseTimer() {
        pauseTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.pauseRemainingSeconds -= 1
                
                if self.pauseRemainingSeconds <= 0 {
                    // 超时自动失败
                    self.pauseTimer?.cancel()
                    self.fail()
                }
            }
    }
    
    // ✅ 新增方法2：延长暂停
    func extendPause() {
        let result = timeCoinManager.extendPause()
        
        switch result {
        case .success(let remaining):
            pauseRemainingSeconds += 1800  // 增加30分钟
            print("✅ 暂停时间延长30分钟，剩余时间币：\(remaining)")
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    // ✅ 新增方法3：保存进度并结束
    func saveProgressAndEnd() {
        let result = timeCoinManager.pauseTask()  // 花2个时间币
        
        switch result {
        case .success:
            pauseTimer?.cancel()
            cancellable?.cancel()
            
            if isHabitFormationTask() {
                // 习惯养成任务：今日标记为完成
                let _ = habitFormationManager.recordDailyCompletion()
                completeWithPartialProgress()
            } else {
                // 日常任务：按进度给经验
                completeWithPartialProgress()
            }
            
            print("✅ 已保存进度并结束任务")
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helper Methods
    
    private func isHabitFormationTask() -> Bool {
        let taskType = habit.value(forKey: "taskType") as? String ?? "daily"
        let isFormation = habit.value(forKey: "isFormationTask") as? Bool ?? false
        return taskType == "formation" || isFormation
    }
    
    private func completeWithPartialProgress() {
        cancellable?.cancel()
        pauseTimer?.cancel()  // ✅ 停止暂停倒计时
        state = .completed
        
        let actualMinutes = elapsedSeconds / 60
        let estimatedMinutes = Int(habit.value(forKey: "estimatedMinutes") as? Int16 ?? 30)
        
        currentRating = ratingManager.calculateRating(
            estimatedMinutes: estimatedMinutes,
            actualMinutes: actualMinutes
        )
        
        earnedBadge = .purist
        saveTaskRecord(wasOnTime: false)
        showCompletionSheet = true
    }
    
    // MARK: - Save Task Record
    private func saveTaskRecord(wasOnTime: Bool) {
        let record = NSEntityDescription.insertNewObject(forEntityName: "TaskRecord", into: context)
        record.setValue(UUID(), forKey: "id")
        record.setValue(habit.value(forKey: "id"), forKey: "habitId")
        record.setValue(startTime ?? Date(), forKey: "startTime")
        record.setValue(Date(), forKey: "endTime")
        record.setValue(habit.value(forKey: "estimatedMinutes"), forKey: "estimatedMinutes")
        record.setValue(Int32(elapsedSeconds / 60), forKey: "actualMinutes")
        record.setValue(currentRating.rawValue, forKey: "rating")
        record.setValue(Int16(delayPackagesUsed), forKey: "delayPackagesUsed")
        record.setValue(habit.value(forKey: "attributeType"), forKey: "attributeType")
        record.setValue(true, forKey: "completed")
        
        if let badge = earnedBadge {
            record.setValue(badge.rawValue, forKey: "badge")
        }
        
        let expGained = ratingManager.calculateExpReward(rating: currentRating, wasOnTime: wasOnTime)
        let attributePoints = ratingManager.calculateAttributePoints(rating: currentRating)
        
        record.setValue(Int32(expGained), forKey: "expGained")
        record.setValue(Int32(attributePoints), forKey: "attributePoints")
        
        do {
            try context.save()

            // 更新用户等级与S徽章计数（双条件升级：经验达标且S徽章>=10）
            let userFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
            var currentLevel = 1
            if let profiles = try context.fetch(userFetch) as? [NSManagedObject], let profile = profiles.first {
                currentLevel = (profile.value(forKey: "level") as? Int) ?? 1
                let requiredExp = ExperienceViewModel.expRequired(for: currentLevel)
                let currentExp = (profile.value(forKey: "currentEXP") as? Int) ?? 0
                let sCount = (profile.value(forKey: "sBadgesThisLevel") as? Int) ?? 0

                // 经验封顶：不超过本级阈值
                let newExp = min(requiredExp, currentExp + max(0, expGained))

                // 若本次评级为S，则S计数+1
                let newS = sCount + (currentRating == .s ? 1 : 0)

                profile.setValue(Int32(newExp), forKey: "currentEXP")
                profile.setValue(Int32((profile.value(forKey: "totalEXP") as? Int ?? 0) + max(0, expGained)), forKey: "totalEXP")
                profile.setValue(Int16(newS), forKey: "sBadgesThisLevel")

                // 升级判定：经验达标且S>=10
                if newExp >= requiredExp && newS >= 10 {
                    profile.setValue(Int16(currentLevel + 1), forKey: "level")
                    profile.setValue(Int32(0), forKey: "currentEXP")
                    profile.setValue(Int16(0), forKey: "sBadgesThisLevel")
                }

                // 更新属性点数
                let attrTypeString = habit.value(forKey: "attributeType") as? String ?? ""
                switch attrTypeString {
                case "力量":
                    let current = (profile.value(forKey: "strengthPoints") as? Int) ?? 0
                    profile.setValue(Int32(current + attributePoints), forKey: "strengthPoints")
                case "智力":
                    let current = (profile.value(forKey: "intelligencePoints") as? Int) ?? 0
                    profile.setValue(Int32(current + attributePoints), forKey: "intelligencePoints")
                case "敏捷":
                    let current = (profile.value(forKey: "agilityPoints") as? Int) ?? 0
                    profile.setValue(Int32(current + attributePoints), forKey: "agilityPoints")
                case "魅力":
                    let current = (profile.value(forKey: "charismaPoints") as? Int) ?? 0
                    profile.setValue(Int32(current + attributePoints), forKey: "charismaPoints")
                default:
                    break
                }

                try context.save()
            }
            print("✅ 任务记录已保存到 Core Data")
            
            NotificationCenter.default.post(
                name: .expChanged,
                object: nil,
                userInfo: ["change": expGained]
            )
            
            if let attributeTypeString = habit.value(forKey: "attributeType") as? String {
                NotificationCenter.default.post(
                    name: .attributeChanged,
                    object: nil,
                    userInfo: [
                        "type": attributeTypeString,
                        "points": attributePoints
                    ]
                )
            }
            
            // 通知任务已完成，触发主页刷新
            NotificationCenter.default.post(name: .taskCompleted, object: nil)
            
            // 若升级，发送升级通知
            if let profiles = try? context.fetch(userFetch) as? [NSManagedObject],
               let profile = profiles.first,
               let levelAfterSave = profile.value(forKey: "level") as? Int,
               levelAfterSave > currentLevel {
                NotificationCenter.default.post(
                    name: .levelUp,
                    object: nil,
                    userInfo: ["newLevel": levelAfterSave]
                )
            }
            
        } catch {
            print("❌ 保存任务记录失败: \(error)")
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
}
