//
//  EditItemSheet.swift
//  Traces
//

import SwiftUI

struct EditItemSheet: View {
    @EnvironmentObject private var store: ChecklistStore
    @Environment(\.dismiss) private var dismiss

    let item: ChecklistItem
    @State private var name: String
    @State private var dueTime: Date
    @State private var importance: Importance

    init(item: ChecklistItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _dueTime = State(initialValue: item.dueTime)
        _importance = State(initialValue: item.importance)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("编辑条目")
                .font(.headline)

            TextField("名称", text: $name)
                .textFieldStyle(.roundedBorder)

            DatePicker("完成时间", selection: $dueTime)

            ImportancePicker(selection: $importance)

            HStack {
                Button("删除", role: .destructive) {
                    store.delete(item.id)
                    dismiss()
                }
                Spacer()
                Button("取消") { dismiss() }
                Button("保存") {
                    var updated = item
                    updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    updated.dueTime = dueTime
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
