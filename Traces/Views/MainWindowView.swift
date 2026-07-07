//
//  MainWindowView.swift
//  Traces
//

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject private var store: ChecklistStore
    @EnvironmentObject private var settings: AppSettings
    @State private var editingItem: ChecklistItem?

    private var sortedTodoItems: [ChecklistItem] {
        store.todoItems.sorted(by: { $0.sortOrder < $1.sortOrder })
    }

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
                .buttonStyle(HoverIconButtonStyle())
                .help("切换语言 / Switch language")

                Button {
                    settings.isDarkMode.toggle()
                } label: {
                    Image(systemName: settings.isDarkMode ? "moon.fill" : "sun.max.fill")
                }
                .buttonStyle(HoverIconButtonStyle())
                .help(settings.isDarkMode ? "切换为浅色模式" : "切换为深色模式")
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 4)

            AddItemFormView()
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(title: "\(L.todoSection.text(settings.language)) (\(store.todoItems.count))")
                        .padding(.top, 14)

                    ForEach(sortedTodoItems) { item in
                        TodoRow(item: item) {
                            editingItem = item
                        } onDelete: {
                            store.delete(item.id)
                        }
                        .padding(.vertical, 6)
                        if item.id != sortedTodoItems.last?.id {
                            Divider()
                        }
                    }

                    SectionHeader(title: "\(L.completedSection.text(settings.language)) (\(store.completedItems.count))")
                        .padding(.top, 20)

                    ForEach(store.completedItems) { item in
                        CompletedRow(item: item) {
                            store.reopen(item.id)
                        } onDelete: {
                            store.delete(item.id)
                        }
                        .padding(.vertical, 6)
                        if item.id != store.completedItems.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 14)
            }
        }
        .frame(minWidth: 420, minHeight: 520)
        .sheet(item: $editingItem) { item in
            EditItemSheet(item: item)
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.primary)
            Divider()
        }
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
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let isOverdue = item.isOverdue(at: context.date)
            HStack {
                Circle()
                    .fill(item.displayColor)
                    .frame(width: 8, height: 8)
                Text(item.name)
                    .foregroundStyle(isOverdue ? AnyShapeStyle(Color.red) : AnyShapeStyle(.primary))
                Spacer()
                Text(item.dueTime.map { Self.timeFormatter.string(from: $0) } ?? L.noDeadlineShort.text(settings.language))
                    .font(.caption)
                    .foregroundStyle(isOverdue ? AnyShapeStyle(Color.red) : AnyShapeStyle(.secondary))
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(HoverIconButtonStyle())
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
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
                .fill(item.displayColor)
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
            .buttonStyle(HoverIconButtonStyle())
        }
    }
}
