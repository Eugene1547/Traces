//
//  CalendarHeatmapView.swift
//  Traces
//

import SwiftUI

/// Compact heatmap calendar for the main window: last/current/next month as continuous
/// week rows (no scrolling), one small rounded square per day (today is a circle), blue
/// intensity encoding how many items are due (pending) or were finished (completed) that
/// day. The stat cards on the right can be scoped to all time / 6 months / 3 months, or
/// to a single day by clicking it.
struct CalendarHeatmapView: View {
    @EnvironmentObject private var store: ChecklistStore
    @EnvironmentObject private var settings: AppSettings
    @State private var range: CalendarRange = .threeMonths
    @State private var selectedDay: Date?
    @State private var hoveredDay: Date?

    private let cellSize: CGFloat = 15
    private let cellSpacing: CGFloat = 4
    private let gutterWidth: CGFloat = 34

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
        VStack(alignment: .leading, spacing: 14) {
            titleHeader
            HStack(alignment: .top, spacing: 24) {
                monthGrid
                statsColumn
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Clicking anywhere outside the day cells clears the selection.
        .contentShape(Rectangle())
        .onTapGesture { selectedDay = nil }
    }

    /// Same construction as the list view's section headers, so both pages share one voice.
    private var titleHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L.calendarSection.text(settings.language))
                .font(.title3.bold())
                .foregroundStyle(.primary)
            Divider()
        }
    }

    /// Capsule chips matching ImportancePicker's style; scope the stat cards.
    /// Disabled while a day is selected (the cards follow the selection then).
    private var rangeChips: some View {
        HStack(spacing: 4) {
            ForEach(CalendarRange.allCases) { option in
                Button {
                    range = option
                } label: {
                    Text(option.label(settings.language))
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(range == option ? Color.secondary.opacity(0.15) : Color.clear)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .disabled(selectedDay != nil)
        .opacity(selectedDay != nil ? 0.4 : 1)
    }

    // MARK: - Month grid

    /// Prev month start (inclusive) and next month end (exclusive): the three months on display.
    private var displayInterval: DateInterval? {
        let currentMonth = startOfMonth(Date())
        guard let start = calendar.date(byAdding: .month, value: -1, to: currentMonth),
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth),
              let nextInterval = calendar.dateInterval(of: .month, for: nextMonth)
        else { return nil }
        return DateInterval(start: start, end: nextInterval.end)
    }

    /// Continuous week rows covering the display interval; every week appears exactly once.
    private var weekRows: [[Date]] {
        guard let interval = displayInterval,
              let firstWeek = calendar.dateInterval(of: .weekOfYear, for: interval.start)
        else { return [] }
        var rows: [[Date]] = []
        var weekStart = firstWeek.start
        while weekStart < interval.end {
            let week = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
            rows.append(week.map { calendar.startOfDay(for: $0) })
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { break }
            weekStart = next
        }
        return rows
    }

    private var monthGrid: some View {
        let today = calendar.startOfDay(for: Date())
        let interval = displayInterval
        return VStack(alignment: .leading, spacing: cellSpacing) {
            ForEach(weekRows, id: \.first) { week in
                HStack(spacing: cellSpacing) {
                    gutter(week: week, today: today)
                    ForEach(week, id: \.self) { day in
                        dayCell(day, interval: interval, today: today)
                    }
                }
            }
        }
    }

    /// Left column: a month label on the week containing that month's 1st,
    /// a tick beside the current week otherwise.
    private func gutter(week: [Date], today: Date) -> some View {
        let label = week
            .first { calendar.component(.day, from: $0) == 1 && (displayInterval?.contains($0) ?? false) }
            .map(monthLabel)
        return ZStack(alignment: .leading) {
            if let label {
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else if week.contains(today) {
                Rectangle()
                    .fill(.secondary)
                    .frame(width: 12, height: 1.5)
            }
        }
        .frame(width: gutterWidth, height: cellSize, alignment: .leading)
    }

    private func dayCell(_ day: Date, interval: DateInterval?, today: Date) -> some View {
        let inRange = interval?.contains(day) ?? false
        let stats = inRange ? statsByDay[day] : nil
        let isToday = inRange && day == today
        let isSelected = inRange && selectedDay == day
        let isHovered = inRange && hoveredDay == day
        let shape = DayCellShape(isCircle: isToday)

        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                selectedDay = (selectedDay == day) ? nil : day
            }
        } label: {
            ZStack {
                shape.fill(baseFill(inRange: inRange))
                shape.fill(Color.heatAccent.opacity(heatOpacity(count: stats?.total ?? 0)))
                if isSelected {
                    shape.strokeBorder(Color.heatAccent, lineWidth: 1.5)
                } else if isHovered {
                    shape.strokeBorder(Color.heatAccent.opacity(0.45), lineWidth: 1)
                }
            }
            .frame(width: cellSize, height: cellSize)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(inRange)
        .onHover { hovering in
            hoveredDay = hovering ? day : (hoveredDay == day ? nil : hoveredDay)
        }
        .help(inRange ? tooltip(day: day, stats: stats) : "")
        .accessibilityLabel(inRange ? tooltip(day: day, stats: stats) : "")
    }

    // MARK: - Colors

    /// In-range empty days read light (near-white on dark, light gray on light);
    /// the few leading/trailing out-of-range days sit barely above the background.
    private func baseFill(inRange: Bool) -> Color {
        if settings.isDarkMode {
            return inRange ? Color.white.opacity(0.85) : Color.white.opacity(0.06)
        }
        return inRange ? Color.primary.opacity(0.10) : Color.primary.opacity(0.04)
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
        return VStack(alignment: .leading, spacing: 8) {
            rangeChips

            // Reserve the caption line so cards don't jump when a day is selected.
            Text(selectedDay.map(dateString) ?? " ")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 2)

            StatCard(
                title: L.completedSection.text(settings.language),
                value: counts.completed
            )
            StatCard(
                title: L.pendingCard.text(settings.language),
                value: counts.pending
            )
        }
        .frame(width: 150, alignment: .leading)
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

    private func monthLabel(_ dayInMonth: Date) -> String {
        switch settings.language {
        case .zh: return "\(calendar.component(.month, from: dayInMonth))月"
        case .en: return Self.monthFormatter.string(from: dayInMonth).uppercased()
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
/// so fill, hover and selection strokes share a code path.
private struct DayCellShape: InsettableShape {
    var isCircle: Bool
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: insetAmount, dy: insetAmount)
        if isCircle {
            return Circle().path(in: inset)
        }
        return RoundedRectangle(cornerRadius: 4.5, style: .continuous).path(in: inset)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(
            // Same surface as AddItemFormView's card, so the two read as one family.
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
