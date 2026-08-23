import WidgetKit
import SwiftUI

private let appGroup = "group.com.pulpo.widget"

private func read(_ key: String, fallback: String = "—") -> String {
    UserDefaults(suiteName: appGroup)?.string(forKey: key) ?? fallback
}

struct PulpoWidgetEntry: TimelineEntry {
    let date: Date
    let balance: String
    let spent: String
    let balanceLabel: String
    let spentLabel: String
}

struct PulpoProvider: TimelineProvider {
    func placeholder(in context: Context) -> PulpoWidgetEntry {
        PulpoWidgetEntry(
            date: Date(),
            balance: "€1,234",
            spent: "€350",
            balanceLabel: "Balance",
            spentLabel: "Spent"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PulpoWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PulpoWidgetEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> PulpoWidgetEntry {
        PulpoWidgetEntry(
            date: Date(),
            balance: read("balance"),
            spent: read("spent"),
            balanceLabel: read("balance_label", fallback: "Balance"),
            spentLabel: read("spent_label", fallback: "Spent")
        )
    }
}

struct PulpoWidgetView: View {
    var entry: PulpoWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Monedero")
                .font(.caption.bold())
                .foregroundStyle(Color(red: 0.80, green: 1, blue: 0.23))
            Text(entry.balanceLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(entry.balance)
                .font(.title2.bold())
            Text(entry.spentLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(entry.spent)
                .font(.headline.bold())
                .foregroundStyle(Color(red: 0.80, green: 1, blue: 0.23))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    }
}

struct PulpoBudgetEntry: TimelineEntry {
    let date: Date
    let month: String
    let leftLabel: String
    let left: String
    let percent: Int
}

struct PulpoBudgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PulpoBudgetEntry {
        PulpoBudgetEntry(date: Date(), month: "2026-08", leftLabel: "Left", left: "€178", percent: 30)
    }

    func getSnapshot(in context: Context, completion: @escaping (PulpoBudgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PulpoBudgetEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry()], policy: .after(Date().addingTimeInterval(1800))))
    }

    private func makeEntry() -> PulpoBudgetEntry {
        PulpoBudgetEntry(
            date: Date(),
            month: read("month_label"),
            leftLabel: read("budget_left_label", fallback: "Left"),
            left: read("budget_left"),
            percent: Int(read("budget_percent", fallback: "0")) ?? 0
        )
    }
}

struct PulpoBudgetWidgetView: View {
    var entry: PulpoBudgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.month).font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("Monedero").font(.caption2.bold()).foregroundStyle(Color(red: 0.80, green: 1, blue: 0.23))
            }
            Text(entry.leftLabel).font(.caption2).foregroundStyle(.secondary)
            Text(entry.left).font(.title.bold()).foregroundStyle(Color(red: 0.80, green: 1, blue: 0.23))
            ProgressView(value: Double(entry.percent), total: 100)
                .tint(Color(red: 0.80, green: 1, blue: 0.23))
            Text("\(entry.percent)%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    }
}

struct PulpoChartEntry: TimelineEntry {
    let date: Date
    let month: String
    let expenseLabel: String
    let spent: String
    let bars: [Int]
}

struct PulpoChartProvider: TimelineProvider {
    func placeholder(in context: Context) -> PulpoChartEntry {
        PulpoChartEntry(date: Date(), month: "2026-08", expenseLabel: "Expense", spent: "€3500", bars: [20, 40, 10, 80, 55, 30, 70])
    }

    func getSnapshot(in context: Context, completion: @escaping (PulpoChartEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PulpoChartEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry()], policy: .after(Date().addingTimeInterval(1800))))
    }

    private func makeEntry() -> PulpoChartEntry {
        let raw = read("daily_bars", fallback: "")
        let bars = raw.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        return PulpoChartEntry(
            date: Date(),
            month: read("month_label"),
            expenseLabel: read("expense_label", fallback: "Expense"),
            spent: read("spent"),
            bars: bars
        )
    }
}

struct PulpoChartWidgetView: View {
    var entry: PulpoChartEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.month).font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("Monedero").font(.caption2.bold()).foregroundStyle(Color(red: 0.80, green: 1, blue: 0.23))
            }
            Text(entry.expenseLabel).font(.caption2).foregroundStyle(.secondary)
            Text(entry.spent).font(.title3.bold()).foregroundStyle(Color(red: 1, green: 0.36, blue: 0.36))
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(entry.bars.enumerated()), id: \.offset) { _, value in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.36, green: 0.56, blue: 0.94))
                        .frame(width: 10, height: CGFloat(max(4, value)))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .bottomLeading)
        }
        .padding()
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    }
}

@main
struct PulpoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PulpoWidget()
        PulpoBudgetWidget()
        PulpoChartWidget()
    }
}

struct PulpoWidget: Widget {
    let kind = "PulpoWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulpoProvider()) { entry in
            PulpoWidgetView(entry: entry)
        }
        .configurationDisplayName("Monedero")
        .description("Balance and monthly spending")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PulpoBudgetWidget: Widget {
    let kind = "PulpoBudgetWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulpoBudgetProvider()) { entry in
            PulpoBudgetWidgetView(entry: entry)
        }
        .configurationDisplayName("Monedero Budget")
        .description("Budget left and progress")
        .supportedFamilies([.systemSmall])
    }
}

struct PulpoChartWidget: Widget {
    let kind = "PulpoChartWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulpoChartProvider()) { entry in
            PulpoChartWidgetView(entry: entry)
        }
        .configurationDisplayName("Monedero Chart")
        .description("Daily expense bars")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
