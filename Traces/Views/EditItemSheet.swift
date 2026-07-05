//
//  EditItemSheet.swift
//  Traces
//

import SwiftUI

struct EditItemSheet: View {
    @EnvironmentObject private var store: ChecklistStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let item: ChecklistItem
    @State private var name: String
    @State private var dueTime: Date
    @State private var hasDueTime: Bool
    @State private var importance: Importance

    init(item: ChecklistItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _dueTime = State(initialValue: item.dueTime ?? Date())
        _hasDueTime = State(initialValue: item.dueTime != nil)
        _importance = State(initialValue: item.importance)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L.editTitle.text(settings.language))
                .font(.headline)

            TextField(L.namePlaceholder.text(settings.language), text: $name)
                .textFieldStyle(.roundedBorder)

            Toggle(
                L.noDeadline.text(settings.language),
                isOn: Binding(get: { !hasDueTime }, set: { hasDueTime = !$0 })
            )
            .toggleStyle(.checkbox)

            if hasDueTime {
                DatePicker(L.dueTimeLabel.text(settings.language), selection: $dueTime)
            }

            ImportancePicker(selection: $importance)

            HStack {
                Button(L.deleteButton.text(settings.language), role: .destructive) {
                    store.delete(item.id)
                    dismiss()
                }
                Spacer()
                Button(L.cancelButton.text(settings.language)) { dismiss() }
                Button(L.saveButton.text(settings.language)) {
                    var updated = item
                    updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    updated.dueTime = hasDueTime ? dueTime : nil
                    updated.importance = importance
                    store.update(updated)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}
