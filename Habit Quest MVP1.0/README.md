# HabitQuest (MVP 1.0)

iOS 16+ 目标，Swift 5.9，SwiftUI + MVVM + Core Data（本地化，无后端）。

## 核心理念
- 通过智能计时与游戏化反馈，将习惯完成转化为四维属性成长（力量/智力/敏捷/魅力）。
- 创新机制：延时包购买系统（指数定价、每日重置）+ 评价降级（S→A→B→C）。
- 完成后根据实际/预估时间比率计算评价并结算 EXP 与属性点。

## 技术栈
- UI: SwiftUI, Combine
- 模式: MVVM
- 数据: Core Data（单库、本地，启用 WAL）

## 目录结构
```
HabitQuest/
  App/
    HabitQuestApp.swift
  CoreData/
    PersistenceController.swift
    CoreDataManager.swift
  Models/
    AppError.swift
    AttributeType.swift
  ViewModels/
    HabitViewModel.swift
    TimerViewModel.swift
    UserProfileViewModel.swift
    StatsViewModel.swift
  Views/
    HomeView.swift
    HabitsView.swift
    StatsView.swift
    SettingsView.swift
    TimerView.swift
  Shared/
    Components/
      AttributeCardView.swift
      ExpFloatingTextView.swift
    Utilities/
      Animations.swift
```

> 注：.xcdatamodeld 文件需在 Xcode 中创建并设置实体与索引；代码中假设实体名与字段如下（详见“数据模型”）。

## 数据模型（Core Data）
- Habit
  - id: UUID (Indexed)
  - name: String
  - attributeType: String
  - estimatedMinutes: Int64
  - createdDate: Date
  - isActive: Bool (default true)

- TaskRecord
  - id: UUID (Indexed)
  - habitId: UUID (Indexed)
  - startTime: Date
  - endTime: Date?
  - estimatedMinutes: Int64
  - actualMinutes: Int64
  - rating: String? (S/A/B/C)
  - originalRating: String?
  - delayPackagesUsed: Int64
  - expGained: Int64
  - expSpent: Int64
  - attributeType: String
  - attributePoints: Int64
  - completed: Bool (Indexed)

- UserProfile（单例，仅一条记录）
  - id: UUID
  - totalEXP: Int64
  - currentEXP: Int64
  - strengthPoints: Int64
  - intelligencePoints: Int64
  - agilityPoints: Int64
  - charismaPoints: Int64
  - createdDate: Date
  - lastActiveDate: Date

- DelayPackageHistory
  - id: UUID
  - taskRecordId: UUID (Indexed)
  - purchaseTime: Date
  - cost: Int64
  - delayMinutes: Int64 (固定 15)
  - dailySequenceNumber: Int64 (当天购买序号)

- DailyStreak
  - id: UUID
  - date: Date (Indexed, day-level)
  - completedCount: Int64
  - totalAttributePoints: Int64

### 索引建议
- TaskRecord: 组合索引 `(habitId, completed)`
- DailyStreak: `date` 索引
- DelayPackageHistory: `taskRecordId` 索引

## 关键业务规则（摘要）
- 评价：
  - 比率 r = actual / estimated
  - r ≤ 1.0 → S (+25 EXP，含 5 点准时奖励)
  - r ≤ 1.2 → A (+15 EXP)
  - r ≤ 1.5 → B (+10 EXP)
  - r > 1.5 → C (+5 EXP)
- 延时包：
  - 到达 80% 进度触发购买提示（C 禁止购买）
  - 每次 +15 分钟；当日第 k 次价格 = 50 × 2^(k-1) EXP（k∈[1,4]，每日 0 点重置）
  - 购买立即触发评价降级（S→A→B→C）

## UI/UX 摘要
- TabView（Home/Habits/Stats/Settings）+ 每个 Tab 内 `NavigationStack`
- 计时进度条三段式：
  - 0-60% #4ECDC4（绿）
  - 60-80% #FFB84D（橙）
  - 80-100% #FF6B6B（红）
- 统一动画：`.spring(response: 0.3, dampingFraction: 0.7)`

## 开发注意
- Core Data 所有操作 `do-catch` + `AppError` 统一化
- 进入后台保存；WAL 模式；禁止 iCloud 备份
- 列表采用 Lazy 栈/延迟加载；查询用 NSPredicate + 索引

## 下一步
- 在 Xcode 中创建项目与 `.xcdatamodeld` 并对应以上实体与字段
- 把本仓库源文件加入项目组与 target
- 逐步实现 ViewModel 逻辑与界面交互
