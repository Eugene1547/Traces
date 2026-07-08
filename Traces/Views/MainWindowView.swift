//
//  MainWindowView.swift
//  Traces
//

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject private var store: ChecklistStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editingItem: ChecklistItem?
    @State private var showCalendar = false

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
                    if reduceMotion {
                        showCalendar.toggle()
                    } else {
                        withAnimation(.easeOut(duration: 0.18)) { showCalendar.toggle() }
                    }
                } label: {
                    Image(systemName: "calendar")
                        .foregroundStyle(showCalendar ? Color.heatAccent : Color.primary)
                }
                .buttonStyle(.plain)
                .help((showCalendar ? L.backToListHelp : L.calendarToggleHelp).text(settings.language))

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
                .help(L.darkModeHelp.text(settings.language))
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 4)

            AddItemFormView()
            Divider()
            if showCalendar {
                CalendarHeatmapView()
                    .transition(.opacity)
            } else {
                listContent
                    .transition(.opacity)
            }
        }
        .frame(minWidth: 420, minHeight: 520)
        .sheet(item: $editingItem) { item in
            EditItemSheet(item: item)
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
    }

    private var listContent: some View {
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
        HStack {
            Circle()
                .fill(item.displayColor)
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
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
}
