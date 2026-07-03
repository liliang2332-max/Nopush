import Foundation
import CoreData
import Combine

// 统计数据视图模型
class StatsViewModel: ObservableObject {
    @Published var todayStats: TodayStats = TodayStats()
    @Published var weekStats: WeekStats = WeekStats()
    @Published var attributeStats: AttributeStats = AttributeStats()
    
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadAllStats()
        setupObservers()
    }
    
    // MARK: - Setup Observers
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .taskCompleted)
            .sink { [weak self] _ in
                self?.loadAllStats()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load All Stats
    func loadAllStats() {
        loadTodayStats()
        loadWeekStats()
        loadAttributeStats()
    }
    
    // MARK: - Today Stats
    private func loadTodayStats() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TaskRecord")
        request.predicate = NSPredicate(
            format: "completed == %@ AND endTime >= %@ AND endTime < %@",
            NSNumber(value: true),
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            if let results = try context.fetch(request) as? [NSManagedObject] {
                let completedCount = results.count
                let sCount = results.filter { ($0.value(forKey: "rating") as? String) == "S" }.count
                let totalExp = results.reduce(0) { $0 + (($1.value(forKey: "expGained") as? Int) ?? 0) }
                
                // 勋章统计
                let puristCount = results.filter { ($0.value(forKey: "badge") as? String) == "纯粹者" }.count
                let challengerCount = results.filter { ($0.value(forKey: "badge") as? String) == "挑战者" }.count
                
                // 属性增长统计
                var attributeGrowth: [String: Int] = [:]
                for result in results {
                    if let attrType = result.value(forKey: "attributeType") as? String,
                       let points = result.value(forKey: "attributePoints") as? Int {
                        attributeGrowth[attrType, default: 0] += points
                    }
                }
                
                DispatchQueue.main.async {
                    self.todayStats = TodayStats(
                        completedTasks: completedCount,
                        sRatingCount: sCount,
                        totalExp: totalExp,
                        puristBadges: puristCount,
                        challengerBadges: challengerCount,
                        attributeGrowth: attributeGrowth,
                        streakDays: self.calculateStreakDays()
                    )
                }
            }
        } catch {
            print("Failed to load today stats: \(error)")
        }
    }
    
    // MARK: - Week Stats
    private func loadWeekStats() {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TaskRecord")
        request.predicate = NSPredicate(
            format: "endTime >= %@ AND endTime < %@",
            startOfWeek as NSDate,
            endOfWeek as NSDate
        )
        
        do {
            if let results = try context.fetch(request) as? [NSManagedObject] {
                let completedTasks = results.filter { ($0.value(forKey: "completed") as? Bool) ?? false }
                let totalTasks = results.count
                
                let sCount = completedTasks.filter { ($0.value(forKey: "rating") as? String) == "S" }.count
                let aCount = completedTasks.filter { ($0.value(forKey: "rating") as? String) == "A" }.count
                let bCount = completedTasks.filter { ($0.value(forKey: "rating") as? String) == "B" }.count
                let cCount = completedTasks.filter { ($0.value(forKey: "rating") as? String) == "C" }.count
                
                let puristCount = completedTasks.filter { ($0.value(forKey: "badge") as? String) == "纯粹者" }.count
                let challengerCount = completedTasks.filter { ($0.value(forKey: "badge") as? String) == "挑战者" }.count
                
                let totalMinutes = completedTasks.reduce(0) { $0 + (($1.value(forKey: "actualMinutes") as? Int) ?? 0) }
                let onTimeCount = completedTasks.filter { task in
                    let actual = (task.value(forKey: "actualMinutes") as? Int) ?? 0
                    let estimated = (task.value(forKey: "estimatedMinutes") as? Int) ?? 1
                    return actual <= estimated
                }.count
                
                DispatchQueue.main.async {
                    self.weekStats = WeekStats(
                        completedTasks: completedTasks.count,
                        totalTasks: totalTasks,
                        sCount: sCount,
                        aCount: aCount,
                        bCount: bCount,
                        cCount: cCount,
                        puristBadges: puristCount,
                        challengerBadges: challengerCount,
                        totalMinutes: totalMinutes,
                        onTimeRate: totalTasks > 0 ? Double(onTimeCount) / Double(totalTasks) : 0
                    )
                }
            }
        } catch {
            print("Failed to load week stats: \(error)")
        }
    }
    
    // MARK: - Attribute Stats
    private func loadAttributeStats() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserProfile")
        
        do {
            if let results = try context.fetch(request) as? [NSManagedObject],
               let profile = results.first {
                let strength = (profile.value(forKey: "strengthPoints") as? Int) ?? 0
                let intelligence = (profile.value(forKey: "intelligencePoints") as? Int) ?? 0
                let agility = (profile.value(forKey: "agilityPoints") as? Int) ?? 0
                let charisma = (profile.value(forKey: "charismaPoints") as? Int) ?? 0
                
                // 计算本周增长
                let weekGrowth = calculateWeekAttributeGrowth()
                
                DispatchQueue.main.async {
                    self.attributeStats = AttributeStats(
                        strength: strength,
                        intelligence: intelligence,
                        agility: agility,
                        charisma: charisma,
                        weekGrowth: weekGrowth
                    )
                }
            }
        } catch {
            print("Failed to load attribute stats: \(error)")
        }
    }
    
    // MARK: - Calculate Week Attribute Growth
    private func calculateWeekAttributeGrowth() -> [String: Int] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TaskRecord")
        request.predicate = NSPredicate(
            format: "completed == %@ AND endTime >= %@ AND endTime < %@",
            NSNumber(value: true),
            startOfWeek as NSDate,
            endOfWeek as NSDate
        )
        
        var growth: [String: Int] = [:]
        
        do {
            if let results = try context.fetch(request) as? [NSManagedObject] {
                for result in results {
                    if let attrType = result.value(forKey: "attributeType") as? String,
                       let points = result.value(forKey: "attributePoints") as? Int {
                        growth[attrType, default: 0] += points
                    }
                }
            }
        } catch {
            print("Failed to calculate week growth: \(error)")
        }
        
        return growth
    }
    
    // MARK: - Calculate Streak Days
    private func calculateStreakDays() -> Int {
        let calendar = Calendar.current
        var streakDays = 0
        var checkDate = Date()
        
        for _ in 0..<30 { // 最多检查30天
            let startOfDay = calendar.startOfDay(for: checkDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TaskRecord")
            request.predicate = NSPredicate(
                format: "completed == %@ AND endTime >= %@ AND endTime < %@",
                NSNumber(value: true),
                startOfDay as NSDate,
                endOfDay as NSDate
            )
            
            do {
                let count = try context.count(for: request)
                if count > 0 {
                    streakDays += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                } else {
                    break
                }
            } catch {
                break
            }
        }
        
        return streakDays
    }
}

// MARK: - Data Models

struct TodayStats {
    var completedTasks: Int = 0
    var sRatingCount: Int = 0
    var totalExp: Int = 0
    var puristBadges: Int = 0
    var challengerBadges: Int = 0
    var attributeGrowth: [String: Int] = [:]
    var streakDays: Int = 0
}

struct WeekStats {
    var completedTasks: Int = 0
    var totalTasks: Int = 0
    var sCount: Int = 0
    var aCount: Int = 0
    var bCount: Int = 0
    var cCount: Int = 0
    var puristBadges: Int = 0
    var challengerBadges: Int = 0
    var totalMinutes: Int = 0
    var onTimeRate: Double = 0
    
    var completionRate: Double {
        totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0
    }
    
    var totalHours: Int {
        totalMinutes / 60
    }
    
    var remainingMinutes: Int {
        totalMinutes % 60
    }
    
    var avgMinutesPerTask: Int {
        completedTasks > 0 ? totalMinutes / completedTasks : 0
    }
}

struct AttributeStats {
    var strength: Int = 0
    var intelligence: Int = 0
    var agility: Int = 0
    var charisma: Int = 0
    var weekGrowth: [String: Int] = [:]
    
    var total: Int {
        strength + intelligence + agility + charisma
    }
    
    var strengthPercent: Double {
        total > 0 ? Double(strength) / Double(total) : 0
    }
    
    var intelligencePercent: Double {
        total > 0 ? Double(intelligence) / Double(total) : 0
    }
    
    var agilityPercent: Double {
        total > 0 ? Double(agility) / Double(total) : 0
    }
    
    var charismaPercent: Double {
        total > 0 ? Double(charisma) / Double(total) : 0
    }
    
    var lowestAttribute: String {
        let attrs = [
            ("力量", strength),
            ("智力", intelligence),
            ("敏捷", agility),
            ("魅力", charisma)
        ]
        return attrs.min(by: { $0.1 < $1.1 })?.0 ?? "魅力"
    }
}

