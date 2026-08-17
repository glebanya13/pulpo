import WidgetKit
import SwiftUI

private let appGroup = "group.com.pulpo.app"

struct PulpoEntry: TimelineEntry {
  let date: Date
  let balance: String
  let spent: String
  let balanceLabel: String
  let spentLabel: String
}

struct PulpoProvider: TimelineProvider {
  func placeholder(in context: Context) -> PulpoEntry {
    snapshot
  }

  func getSnapshot(in context: Context, completion: @escaping (PulpoEntry) -> Void) {
    completion(snapshot)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PulpoEntry>) -> Void) {
    let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    completion(Timeline(entries: [snapshot], policy: .after(next)))
  }

  private var snapshot: PulpoEntry {
    let d = UserDefaults(suiteName: appGroup)
    return PulpoEntry(
      date: Date(),
      balance: d?.string(forKey: "balance") ?? "—",
      spent: d?.string(forKey: "spent") ?? "—",
      balanceLabel: d?.string(forKey: "balance_label") ?? "SALDO",
      spentLabel: d?.string(forKey: "spent_label") ?? "GASTO"
    )
  }
}

struct PulpoWidgetView: View {
  var entry: PulpoEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Pulpo")
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(Color(red: 0.80, green: 1.0, blue: 0.23))
      Text(entry.balanceLabel)
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(.white.opacity(0.55))
      Text(entry.balance)
        .font(.system(size: 22, weight: .heavy))
        .foregroundColor(.white)
        .minimumScaleFactor(0.6)
        .lineLimit(1)
      Spacer(minLength: 4)
      Text(entry.spentLabel)
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(.white.opacity(0.55))
      Text(entry.spent)
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(Color(red: 0.80, green: 1.0, blue: 0.23))
        .minimumScaleFactor(0.6)
        .lineLimit(1)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(red: 0.06, green: 0.06, blue: 0.06))
    .widgetURL(URL(string: "pulpo://home"))
  }
}

struct PulpoWidget: Widget {
  let kind: String = "PulpoWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PulpoProvider()) { entry in
      PulpoWidgetView(entry: entry)
    }
    .configurationDisplayName("Pulpo")
    .description("Saldo y gasto del mes")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
