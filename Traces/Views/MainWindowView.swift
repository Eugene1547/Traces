//
//  MainWindowView.swift
//  Traces
//

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject private var store: ChecklistStore
    @EnvironmentObject private var settings: AppSettings
    @State private var editingItem: ChecklistItem?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Traces")
                    .font(.headline)
                Spacer()
                Button {
                    settings.isDarkMode.toggle()
                } label: {
                    Image(systemName: settings.isDarkMode ? "moon.fill" : "sun.max.fill")
                }
                .buttonStyle(.plain)
                .help(settings.isDarkMode ? "切换为浅色模式" : "切换为深色模式")
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 4)

            AddItemFormView()
            Divider()
            List {
                Section("待办 (\(store.todoItems.count))") {
                    ForEach(store.todoItems.sorted(by: { $0.sortOrder < $1.sortOrder })) { item in
                        TodoRow(item: item) {
                            editingItem = item
                        } onDelete: {
                            store.delete(item.id)
                        }
                    }
                }

                Section("已完成 (\(store.completedItems.count))") {
                    ForEach(store.completedItems) { item in
                        CompletedRow(item: item) {
                            store.reopen(item.id)
                        } onDelete: {
                            store.delete(item.id)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
        .frame(minWidth: 420, minHeight: 520)
        .sheet(item: $editingItem) { item in
            EditItemSheet(item: item)
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
    }
}

private struct TodoRow: View {
    let item: ChecklistItem
    let onTap: () -> Void
    let onDelete: () -> Void

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack {
            Circle()
                .fill(item.importance.color)
                .frame(width: 8, height: 8)
            Text(item.name)
            Spacer()
            Text(Self.timeFormatter.string(from: item.dueTime))
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

private struct CompletedRow: View {
    let item: ChecklistItem
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(item.importance.color)
                .frame(width: 8, height: 8)
            Text(item.name)
                .strikethrough()
                .foregroundStyle(.secondary)
            Spacer()
            Button("恢复", action: onRestore)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
}
