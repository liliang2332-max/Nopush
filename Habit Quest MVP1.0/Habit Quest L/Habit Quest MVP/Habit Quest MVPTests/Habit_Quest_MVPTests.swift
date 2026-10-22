//
//  Habit_Quest_MVPTests.swift
//  Habit Quest MVPTests
//
//  Created by 李靓 on 10/29/25.
//

import Testing
@testable import Habit_Quest_MVP

struct Habit_Quest_MVPTests {

    @Test func homeTaskPoolContainsOneHundredUniqueTasks() {
        #expect(StayHomeTaskPool.tasks.count == 100)
        #expect(Set(StayHomeTaskPool.tasks.map(\.title)).count == 100)
    }

}
