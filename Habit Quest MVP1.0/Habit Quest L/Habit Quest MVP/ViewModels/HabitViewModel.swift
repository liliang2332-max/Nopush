import Foundation
import CoreData
import Combine

class HabitViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    @Published var activeHabits: [Habit] = []
    @Published var formationTasks: [Habit] = []
    @Published var completedHabits: [Habit] = []
    @Published var errorMessage: String?
    @Published var availableTimeCoins: Int32 = 5
    
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        fetchHabits()
        updateAvailableTimeCoins()
    }
    
    // MARK: - 获取所有习惯
    func fetchHabits() {
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.createdDate, ascending: false)]
        
        do {
            let allHabits = try context.fetch(request)
            
            // 分类:活跃的、已完成的
            habits = allHabits.filter { !$0.challengeCompleted }  // 未完成的显示
            activeHabits = habits.filter { $0.isActive }
            formationTasks = habits.filter { $0.isFormationTask && !$0.challengeCompleted }
            completedHabits = allHabits.filter { $0.challengeCompleted }  // 已完成的隐藏
            
        } catch {
            errorMessage = "获取习惯失败: \(error.localizedDescription)"
            print("❌ \(errorMessage ?? "")")
        }
    }
    
    // MARK: - 创建新习惯
    @discardableResult
    func createHabit(name: String, attributeType: String, estimatedMinutes: Int16, isFormationTask: Bool) -> Habit {
        let newHabit = Habit(context: context)
        newHabit.id = UUID()
        newHabit.name = name
        newHabit.attributeType = attributeType
        newHabit.estimatedMinutes = estimatedMinutes
        newHabit.isFormationTask = isFormationTask
        newHabit.isActive = true
        newHabit.createdDate = Date()
        newHabit.completedCount = 0
        newHabit.currentStreak = 0
        newHabit.maxStreak = 0
        newHabit.usedTimeCoins = 0
        newHabit.totalExperience = 0
        newHabit.challengeCompleted = false
        
        if isFormationTask {
            newHabit.startDate = Date()
            // 21天后的日期
            newHabit.endDate = Calendar.current.date(byAdding: .day, value: 21, to: Date())
        }
        
        saveContext()
        fetchHabits()
        return newHabit
    }
    
    // MARK: - 删除习惯
    func deleteHabit(_ habit: Habit) {
        context.delete(habit)
        saveContext()
        fetchHabits()
    }
    
    // MARK: - 完成任务
    func completeTask(habit: Habit) {
        // 更新完成日期
        habit.lastCompletedDate = Date()
        
        // 更新完成次数
        habit.completedCount += 1
        
        // 更新连续天数
        updateStreak(for: habit)
        
        // 计算并添加经验值
        let experience = calculateExperience(for: habit)
        habit.totalExperience += Int32(experience)
        addExperience(experience)
        
        // 更新用户属性
        updateAttributes(for: habit)
        
        // 更新评级(如果是21天挑战)
        if habit.isFormationTask {
            updateRating(for: habit)
            checkChallengeCompletion(for: habit)
        }
        
        // 保存
        saveContext()
        fetchHabits()
        
        print("✅ 任务完成: \(habit.name ?? "未知"), 经验值+\(experience)")
    }
    
    // MARK: - 时间币管理
    
    // 更新可用时间币数量
    func updateAvailableTimeCoins() {
        checkAndResetTimeCoins()
        
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            if let userProfile = profiles.first {
                availableTimeCoins = userProfile.timeCoins
            } else {
                createDefaultUserProfile()
                availableTimeCoins = 5
            }
        } catch {
            print("❌ 获取时间币失败: \(error)")
            availableTimeCoins = 0
        }
    }
    
    // 检查并重置每周时间币
    private func checkAndResetTimeCoins() {
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            guard let userProfile = profiles.first else {
                createDefaultUserProfile()
                return
            }
            
            let calendar = Calendar.current
            let now = Date()
            
            // 检查是否需要重置(每周一重置)
            if let lastReset = userProfile.lastTimeCoinReset {
                let daysPassed = calendar.dateComponents([.day], from: lastReset, to: now).day ?? 0
                
                // 如果超过7天,重置时间币
                if daysPassed >= 7 {
                    resetWeeklyTimeCoins()
                }
            } else {
                // 第一次使用,初始化
                resetWeeklyTimeCoins()
            }
        } catch {
            print("❌ 检查时间币失败: \(error)")
        }
    }
    
    // 重置每周时间币
    private func resetWeeklyTimeCoins() {
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            guard let userProfile = profiles.first else { return }
            
            userProfile.timeCoins = 5  // 每周5个
            userProfile.lastTimeCoinReset = Date()
            
            saveContext()
            availableTimeCoins = 5
            print("🪙 时间币已重置: 5个")
        } catch {
            print("❌ 重置时间币失败: \(error)")
        }
    }
    
    // 使用时间币
    func useTimeCoin(for habit: Habit) -> Bool {
        guard habit.isFormationTask else {
            errorMessage = "只有习惯养成任务可以使用时间币"
            return false
        }
        
        updateAvailableTimeCoins()
        
        guard availableTimeCoins > 0 else {
            errorMessage = "时间币不足,请等待下周重置"
            return false
        }
        
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            guard let userProfile = profiles.first else { return false }
            
            // 扣除用户时间币
            userProfile.timeCoins -= 1
            
            // 记录习惯使用的时间币
            habit.usedTimeCoins += 1
            
            // 更新评级
            updateRating(for: habit)
            
            saveContext()
            updateAvailableTimeCoins()
            
            print("⏰ 使用时间币成功, 剩余: \(userProfile.timeCoins), 习惯已使用: \(habit.usedTimeCoins)")
            return true
        } catch {
            print("❌ 使用时间币失败: \(error)")
            errorMessage = "使用时间币失败"
            return false
        }
    }
    
    // 获取下次重置时间
    func getNextResetDate() -> Date? {
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            guard let userProfile = profiles.first,
                  let lastReset = userProfile.lastTimeCoinReset else {
                return nil
            }
            
            return Calendar.current.date(byAdding: .day, value: 7, to: lastReset)
        } catch {
            return nil
        }
    }
    
    // MARK: - 获取今日完成数量
    func getTodayCompletedCount() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "lastCompletedDate >= %@", today as NSDate)
        
        do {
            let results = try context.fetch(request)
            return results.count
        } catch {
            print("❌ 获取今日完成数失败: \(error)")
            return 0
        }
    }
    
    // MARK: - 私有辅助函数
    
    // 更新连续天数
    private func updateStreak(for habit: Habit) {
        guard let lastCompleted = habit.lastCompletedDate else {
            habit.currentStreak = 1
            habit.maxStreak = 1
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastCompleted)
        let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        
        if daysDifference == 1 {
            habit.currentStreak += 1
            if habit.currentStreak > habit.maxStreak {
                habit.maxStreak = habit.currentStreak
            }
            print("🔥 连续天数: \(habit.currentStreak)")
        } else if daysDifference > 1 {
            habit.currentStreak = 1
            print("💔 连续中断,重新开始")
        } else if daysDifference == 0 {
            print("ℹ️ 今天已经完成过了")
        }
    }
    
    // 计算经验值
    private func calculateExperience(for habit: Habit) -> Int {
        let baseExperience = Int(habit.estimatedMinutes) / 5
        let streakBonus = Int(habit.currentStreak) * 2
        let formationBonus = habit.isFormationTask ? 10 : 0
        let totalExperience = max(1, baseExperience + streakBonus + formationBonus)
        
        print("📊 经验值计算: 基础=\(baseExperience), 连续奖励=\(streakBonus), 挑战奖励=\(formationBonus), 总计=\(totalExperience)")
        
        return totalExperience
    }
    
    // 添加经验值到用户
    private func addExperience(_ amount: Int) {
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            
            if let userProfile = profiles.first {
                userProfile.totalEXP += Int32(amount)
                let newLevel = Int16(userProfile.totalEXP / 100)
                userProfile.level = newLevel
                
                print("✨ 用户获得 \(amount) 经验值, 总经验: \(userProfile.totalEXP), 等级: \(newLevel)")
            } else {
                createDefaultUserProfile()
                addExperience(amount)
            }
        } catch {
            print("❌ 获取用户档案失败: \(error)")
        }
    }
    
    // 更新用户属性
    private func updateAttributes(for habit: Habit) {
        let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        
        do {
            let profiles = try context.fetch(fetchRequest)
            
            guard let userProfile = profiles.first else {
                print("⚠️ 未找到用户档案")
                createDefaultUserProfile()
                return
            }
            
            let attributePoints = Int16(habit.estimatedMinutes / 10)
            let points = max(1, attributePoints)
            
            switch habit.attributeType?.lowercased() {
            case "力量":
                userProfile.strengthPoints += Int32(points)
                print("💪 力量 +\(points), 当前: \(userProfile.strengthPoints)")
                
            case "智力":
                userProfile.intelligencePoints += Int32(points)
                print("🧠 智力 +\(points), 当前: \(userProfile.intelligencePoints)")
                
            case "敏捷":
                userProfile.agilityPoints += Int32(points)
                print("⚡ 敏捷 +\(points), 当前: \(userProfile.agilityPoints)")
                
            case "魅力":
                userProfile.charismaPoints += Int32(points)
                print("✨ 魅力 +\(points), 当前: \(userProfile.charismaPoints)")
                
            default:
                print("⚠️ 未知属性类型: \(habit.attributeType ?? "nil")")
            }
            
        } catch {
            print("❌ 更新属性失败: \(error)")
        }
    }
    
    // 更新评级
    private func updateRating(for habit: Habit) {
        let usedCoins = habit.usedTimeCoins
        
        if usedCoins == 0 {
            habit.rating = "S"
        } else if usedCoins <= 2 {
            habit.rating = "A"
        } else if usedCoins <= 4 {
            habit.rating = "B"
        } else {
            habit.rating = "C"
        }
        
        print("⭐ 评级更新为: \(habit.rating ?? "未知"), 已使用时间币: \(usedCoins)")
    }
    
    // 检查21天挑战是否完成
    private func checkChallengeCompletion(for habit: Habit) {
        guard habit.isFormationTask, let startDate = habit.startDate else {
            return
        }
        
        let calendar = Calendar.current
        let daysPassed = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        
        // 21天挑战完成条件:
        // 1. 至少过了21天
        // 2. 完成次数达标(15次基础 + 使用的时间币可以减少要求)
        let requiredCompletions = max(15, 18 - Int(habit.usedTimeCoins))
        
        if daysPassed >= 21 && Int(habit.completedCount) >= requiredCompletions {
            habit.challengeCompleted = true
            habit.isActive = false  // 标记为不活跃
            
            // 给予完成奖励
            let bonusExperience = 500
            addExperience(bonusExperience)
            
            print("🎉 21天挑战完成! 评级: \(habit.rating ?? "未知"), 奖励经验: \(bonusExperience)")
        }
    }
    
    // 创建默认用户档案
    private func createDefaultUserProfile() {
        let newProfile = UserProfile(context: context)
        newProfile.id = UUID()
        newProfile.level = 0
        newProfile.totalEXP = 0
        newProfile.strengthPoints = 0
        newProfile.intelligencePoints = 0
        newProfile.agilityPoints = 0
        newProfile.charismaPoints = 0
        newProfile.timeCoins = 5
        newProfile.lastTimeCoinReset = Date()
        newProfile.createdDate = Date()
        
        saveContext()
        print("✅ 创建了默认用户档案")
    }
    
    // 保存上下文
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                print("💾 数据保存成功")
            } catch {
                errorMessage = "保存失败: \(error.localizedDescription)"
                print("❌ \(errorMessage ?? "")")
            }
        }
    }
}
