//
//  AddItemFormView.swift
//  Traces
//

import SwiftUI

struct AddItemFormView: View {
    @EnvironmentObject private var store: ChecklistStore
    @State private var name = ""
    @State private var dueTime = Date()
    @State private var importance: Importance = .medium

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("名称", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit(add)

            HStack {
                DatePicker("", selection: $dueTime)
                    .labelsHidden()

                ImportancePicker(selection: $importance)

                Spacer()

                Button("添加", action: add)
                    .disabled(!canAdd)
            }
        }
        .padding()
    }

    private func add() {
        guard canAdd else { return }
        store.addItem(name: name, dueTime: dueTime, importance: importance)
        name = ""
        importance = .medium
        dueTime = Date()
    }
}
