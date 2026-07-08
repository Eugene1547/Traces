//
//  CalendarHeatmapView.swift
//  Traces
//

import SwiftUI

/// GitHub-style heatmap calendar for the main window: one row per week, one rounded square
/// per day (today is a circle), blue intensity encoding how many items are due (pending)
/// or were finished (completed) that day. A segmented range control scopes both the visible
/// months and the stat cards on the right; clicking a day scopes the cards to that day.
struct CalendarHeatmapView: View {
    @EnvironmentObject private var store: ChecklistStore
    @EnvironmentObject private var settings: AppSettings
    @State private var range: CalendarRange = .threeMonths
    @State private var selectedDay: Date?

    private let cellSize: CGFloat = 26
    private let cellSpacing: CGFloat = 5
    private let gutterWidth: CGFloat = 42

    private var calendar: Calendar { .current }

    private struct DayStats {
        var pending = 0
        var completed = 0
        var total: Int { pending + completed }
    }

    /// Pending items keyed by due day, completed items keyed by completion day.
    /// Undated pending items never enter the grid (they still count in the cards).
    private var statsByDay: [Date: DayStats] {
        var result: [Date: DayStats] = [:]
        for item in store.items {
            if item.isCompleted {
                let day = calendar.startOfDay(for: item.completedAt ?? item.createdAt)
                result[day, default: DayStats()].completed += 1
            } else if let due = item.dueTime {
                let day = calendar.startOfDay(for: due)
                result[day, default: DayStats()].pending += 1
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $range) {
                ForEach(CalendarRange.allCases) { range in
                    Text(range.label(settings.language)).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 280)

            HStack(alignment: .top, spacing: 16) {
                monthGrid
                statsColumn
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .onChange(of: range) { _ in selectedDay = nil }
    }

    // MARK: - Month grid

    private var monthGrid: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(monthStarts, id: \.self) { month in
                        monthBlock(month)
                            .id(month)
                    }
                }
                .padding(.vertical, 6)
            }
            // Land on the current month; .all can start years back.
            .onAppear { proxy.scrollTo(startOfMonth(Date()), anchor: .center) }
            .onChange(of: range) { _ in proxy.scrollTo(startOfMonth(Date()), anchor: .center) }
        }
        // Clicking the empty area around cells clears the day selection.
        .contentShape(Rectangle())
        .onTapGesture { selectedDay = nil }
    }

    /// First-of-month dates covered by the selected range, oldest first.
    private var monthStarts: [Date] {
        let currentMonth = startOfMonth(Date())
        let offsets: ClosedRange<Int>
        switch range {
        case .threeMonths:
            offsets = -1...1
        case .sixMonths:
            offsets = -1...4
        case .all:
            let earliestDay = statsByDay.keys.min() ?? Date()
            let earliestMonth = startOfMonth(earliestDay)
            let monthsBack = calendar.dateComponents([.month], from: earliestMonth, to: currentMonth).month ?? 0
            offsets = -max(monthsBack, 1)...1
        }
        return offsets.compactMap { calendar.date(byAdding: .month, value: $0, to: currentMonth) }
    }

    private func monthBlock(_ monthStart: Date) -> some View {
        let today = calendar.startOfDay(for: Date())
        let isCurrentMonth = calendar.isDate(monthStart, equalTo: today, toGranularity: .month)
        return VStack(alignment: .leading, spacing: cellSpacing) {
            ForEach(Array(weeks(in: monthStart).enumerated()), id: \.offset) { rowIndex, week in
                HStack(spacing: cellSpacing) {
                    gutter(
                        showLabel: rowIndex == 0,
                        showTick: isCurrentMonth && week.contains(today),
                        monthStart: monthStart
                    )
                    ForEach(week, id: \.self) { day in
                        dayCell(day, monthStart: monthStart, today: today)
                    }
                }
            }
        }
    }

    /// Weeks overlapping the month. Boundary weeks are repeated in the adjacent month's
    /// block with the out-of-month days dimmed, matching the reference design.
    private func weeks(in monthStart: Date) -> [[Date]] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthStart),
              let firstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start)
        else { return [] }
        var result: [[Date]] = []
        var weekStart = firstWeek.start
        while weekStart < monthInterval.end {
            let week = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
            result.append(week.map { calendar.startOfDay(for: $0) })
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { break }
            weekStart = next
        }
        return result
    }

    /// Left column: month label on the block's first row, a tick beside the current week.
    private func gutter(showLabel: Bool, showTick: Bool, monthStart: Date) -> some View {
        ZStack(alignment: .leading) {
            if showLabel {
                Text(monthLabel(monthStart))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else if showTick {
                Rectangle()
                    .fill(.secondary)
                    .frame(width: 14, height: 1.5)
            }
        }
        .frame(width: gutterWidth, height: cellSize, alignment: .leading)
    }

    private func dayCell(_ day: Date, monthStart: Date, today: Date) -> some View {
        let inMonth = calendar.isDate(day, equalTo: monthStart, toGranularity: .month)
        let stats = inMonth ? statsByDay[day] : nil
        let isToday = inMonth && day == today
        let isSelected = inMonth && selectedDay == day
        let shape = DayCellShape(isCircle: isToday)

        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                selectedDay = (selectedDay == day) ? nil : day
            }
        } label: {
            ZStack {
                shape.fill(baseFill(inMonth: inMonth))
                shape.fill(Color.heatAccent.opacity(heatOpacity(count: stats?.total ?? 0)))
                if isSelected {
                    shape.strokeBorder(Color.heatAccent, lineWidth: 2)
                }
            }
            .frame(width: cellSize, height: cellSize)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(inMonth)
        .help(inMonth ? tooltip(day: day, stats: stats) : "")
        .accessibilityLabel(inMonth ? tooltip(day: day, stats: stats) : "")
    }

    // MARK: - Colors

    /// Empty in-month days read light (near-white on dark, light gray on light);
    /// out-of-month days sit barely above the window background.
    private func baseFill(inMonth: Bool) -> Color {
        if settings.isDarkMode {
            return inMonth ? Color.white.opacity(0.85) : Color.white.opacity(0.06)
        }
        return inMonth ? Color.primary.opacity(0.10) : Color.primary.opacity(0.04)
    }

    /// Blends the indigo accent over the light base: 1 item is a pale wash, 4+ is full accent.
    /// Exact counts are always available via tooltip/accessibility, never color alone.
    private func heatOpacity(count: Int) -> Double {
        switch count {
        case ..<1: return 0
        case 1: return 0.3
        case 2: return 0.55
        case 3: return 0.8
        default: return 1.0
        }
    }

    // MARK: - Stats column

    private var statsColumn: some View {
        let counts = displayedCounts
        return VStack(alignment: .leading, spacing: 10) {
            // Reserve the caption line so cards don't jump when a day is selected.
            Text(selectedDay.map(dateString) ?? " ")
                .font(.caption)
                .foregroundStyle(.secondary)
            StatCard(
                title: L.completedSection.text(settings.language),
                value: counts.completed,
                isDark: settings.isDarkMode
            )
            StatCard(
                title: L.pendingCard.text(settings.language),
                value: counts.pending,
                isDark: settings.isDarkMode
            )
        }
        .frame(width: 128)
    }

    private var displayedCounts: (completed: Int, pending: Int) {
        if let day = selectedDay {
            let stats = statsByDay[day] ?? DayStats()
            return (stats.completed, stats.pending)
        }
        switch range {
        case .all:
            return (store.completedItems.count, store.todoItems.count)
        case .threeMonths, .sixMonths:
            guard let interval = rangeInterval else {
                return (store.completedItems.count, store.todoItems.count)
            }
            let completed = store.completedItems
                .filter { interval.contains($0.completedAt ?? $0.createdAt) }
                .count
            // Undated pending items are always "current", so they count in every range.
            let pending = store.todoItems
                .filter { $0.dueTime.map(interval.contains) ?? true }
                .count
            return (completed, pending)
        }
    }

    private var rangeInterval: DateInterval? {
        let currentMonth = startOfMonth(Date())
        let endOffset = range == .threeMonths ? 2 : 5
        guard let start = calendar.date(byAdding: .month, value: -1, to: currentMonth),
              let end = calendar.date(byAdding: .month, value: endOffset, to: currentMonth)
        else { return nil }
        return DateInterval(start: start, end: end)
    }

    // MARK: - Formatting

    private func startOfMonth(_ date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }

    private func monthLabel(_ monthStart: Date) -> String {
        switch settings.language {
        case .zh: return "\(calendar.component(.month, from: monthStart))月"
        case .en: return Self.monthFormatter.string(from: monthStart).uppercased()
        }
    }

    private func dateString(_ day: Date) -> String {
        let formatter = settings.language == .zh ? Self.zhDayFormatter : Self.enDayFormatter
        return formatter.string(from: day)
    }

    private func tooltip(day: Date, stats: DayStats?) -> String {
        let stats = stats ?? DayStats()
        let todo = L.todoSection.text(settings.language)
        let done = L.completedSection.text(settings.language)
        return "\(dateString(day)) · \(todo) \(stats.pending) · \(done) \(stats.completed)"
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private static let zhDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    private static let enDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

extension Color {
    /// #5B51E8 — heatmap accent, same indigo family as `dragAccent`.
    static let heatAccent = Color(red: 0x5B / 255.0, green: 0x51 / 255.0, blue: 0xE8 / 255.0)
}

/// Rounded square for regular days, circle for today, usable as one insettable shape
/// so fill and selection stroke share a code path.
private struct DayCellShape: InsettableShape {
    var isCircle: Bool
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: insetAmount, dy: insetAmount)
        if isCircle {
            return Circle().path(in: inset)
        }
        return RoundedRectangle(cornerRadius: 7, style: .continuous).path(in: inset)
    }

    func inset(by amount: CGFloat) -> DayCellShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}

private struct StatCard: View {
    let title: String
    let value: Int
    let isDark: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .opacity(0.85)
            Text("\(value)")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .contentTransition(.numericText())
        }
        .foregroundStyle(isDark ? Color.white : Color.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isDark ? Color.white.opacity(0.32) : Color.primary.opacity(0.08))
        )
    }
}
