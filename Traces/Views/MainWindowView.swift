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
                    settings.language = settings.language == .zh ? .en : .zh
                } label: {
                    Text(settings.language.shortLabel)
                        .font(.caption.bold())
                }
                .buttonStyle(.plain)
                .help("切换语言 / Switch language")

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
                Section {
                    ForEach(store.todoItems.sorted(by: { $0.sortOrder < $1.sortOrder })) { item in
                        TodoRow(item: item) {
                            editingItem = item
                        } onDelete: {
                            store.delete(item.id)
                        }
                    }
                } header: {
                    Text("\(L.todoSection.text(settings.language)) (\(store.todoItems.count))")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                }

                Section {
                    ForEach(store.completedItems) { item in
                        CompletedRow(item: item) {
                            store.reopen(item.id)
                        } onDelete: {
                            store.delete(item.id)
                        }
                    }
                } header: {
                    Text("\(L.completedSection.text(settings.language)) (\(store.completedItems.count))")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
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
    @EnvironmentObject private var settings: AppSettings
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
            Text(item.dueTime.map { Self.timeFormatter.string(from: $0) } ?? L.noDeadlineShort.text(settings.language))
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
    @EnvironmentObject private var settings: AppSettings
    let item: ChecklistItem
    let onRestore: () -> Void
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
                .strikethrough()
                .foregroundStyle(.secondary)
            Spacer()
            Text(Self.timeFormatter.string(from: item.completedAt ?? item.createdAt))
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(L.restoreButton.text(settings.language), action: onRestore)
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
