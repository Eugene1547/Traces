//
//  AddItemFormView.swift
//  Traces
//

import SwiftUI

struct AddItemFormView: View {
    @EnvironmentObject private var store: ChecklistStore
    @EnvironmentObject private var settings: AppSettings
    @State private var name = ""
    @State private var dueTime = AddItemFormView.nextFullHour()
    @State private var hasDueTime = true
    @State private var importance: Importance = .medium
    @State private var customColor: RGBAColor?

    /// Default due time: the upcoming full hour (14:37 → 15:00). Snapping down instead would
    /// produce a time already in the past, making a freshly added item instantly overdue.
    private static func nextFullHour(after date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        guard let floor = calendar.date(from: components),
              let next = calendar.date(byAdding: .hour, value: 1, to: floor) else { return date }
        return next
    }

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L.newTodoTitle.text(settings.language))
                .font(.title3.bold())

            VStack(alignment: .leading, spacing: 10) {
                TextField(L.namePlaceholder.text(settings.language), text: $name)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(add)

                HStack {
                    Toggle(
                        L.noDeadline.text(settings.language),
                        isOn: Binding(get: { !hasDueTime }, set: { hasDueTime = !$0 })
                    )
                    .toggleStyle(.checkbox)

                    if hasDueTime {
                        DatePicker("", selection: $dueTime)
                            .labelsHidden()
                            .padding(.trailing, 8)
                    }
                }

                HStack {
                    ImportancePicker(selection: $importance, customColor: $customColor)

                    Spacer()

                    Button(L.addButton.text(settings.language), action: add)
                        .disabled(!canAdd)
                }
            }
            .padding(12)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding()
    }

    private func add() {
        guard canAdd else { return }
        store.addItem(name: name, dueTime: hasDueTime ? dueTime : nil, importance: importance, customColor: customColor)
        name = ""
        importance = .medium
        customColor = nil
        dueTime = Self.nextFullHour()
        hasDueTime = true
    }
}
