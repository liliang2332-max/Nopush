import SwiftUI

struct HabitsView: View {
	@StateObject private var vm = HabitViewModel()
	@State private var showingAdd = false

	var body: some View {
		NavigationStack {
			List {
				ForEach(vm.habits, id: \.self) { habit in
					HStack {
						Text(habit.name ?? "")
						Spacer()
						Text(AttributeType(rawValue: habit.attributeType ?? "")?.displayName ?? "")
					}
				}
				.onDelete { indexSet in
					indexSet.compactMap { vm.habits[$0] }.forEach { vm.softDelete($0) }
				}
			}
			.navigationTitle("习惯")
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button { showingAdd = true } label: { Image(systemName: "plus") }
				}
			}
		}
		.onAppear { vm.loadActiveHabits() }
		.sheet(isPresented: $showingAdd) {
			AddHabitSheet { name, attr, minutes in
				vm.addHabit(name: name, attribute: attr, estimatedMinutes: minutes)
			}
		}
	}
}

private struct AddHabitSheet: View {
	var onSave: (String, AttributeType, Int) -> Void
	@Environment(\.dismiss) private var dismiss
	@State private var name: String = ""
	@State private var attribute: AttributeType = .strength
	@State private var minutes: Int = 30

	var body: some View {
		NavigationStack {
			Form {
				TextField("名称", text: $name)
				Picker("属性", selection: $attribute) {
					ForEach(AttributeType.allCases) { Text($0.displayName).tag($0) }
				}
				Stepper(value: $minutes, in: 5...240, step: 5) { Text("预估时间：\(minutes) 分钟") }
			}
			.navigationTitle("新建习惯")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
				ToolbarItem(placement: .confirmationAction) { Button("保存") { onSave(name, attribute, minutes); dismiss() } }
			}
		}
	}
}
