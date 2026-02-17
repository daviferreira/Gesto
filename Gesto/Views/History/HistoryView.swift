import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionRecord.startedAt, order: .reverse) private var records: [SessionRecord]
    @State private var searchText = ""

    private var filteredRecords: [SessionRecord] {
        if searchText.isEmpty { return records }
        return records.filter { $0.boardName.localizedCaseInsensitiveContains(searchText) }
    }

    private var thisWeekRecords: [SessionRecord] {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else {
            return []
        }
        return records.filter { $0.startedAt >= weekStart }
    }

    var body: some View {
        Group {
            if records.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    title: "No sessions yet",
                    message: "Complete a drawing session to see your history here"
                )
            } else {
                List {
                    weekSummarySection

                    Section("Sessions") {
                        ForEach(filteredRecords) { record in
                            SessionRow(record: record)
                        }
                        .onDelete(perform: deleteRecords)
                    }
                }
            }
        }
        .navigationTitle("History")
        .searchable(text: $searchText, prompt: "Filter sessions")
    }

    // MARK: - Week Summary

    private var weekSummarySection: some View {
        Section("This Week") {
            HStack(spacing: 0) {
                weekStat(
                    "\(thisWeekRecords.count)",
                    label: "sessions"
                )
                Divider().frame(height: 32)
                weekStat(
                    formatDuration(thisWeekRecords.reduce(0) { $0 + $1.duration }),
                    label: "total time"
                )
                Divider().frame(height: 32)
                weekStat(
                    "\(thisWeekRecords.reduce(0) { $0 + $1.imageCount })",
                    label: "images"
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }

    private func weekStat(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold().monospacedDigit())
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredRecords[index])
        }
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let record: SessionRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(record.boardName)
                        .font(.title3)
                    if record.completedAllImages {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
                Text(record.startedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(record.duration))
                    .font(.body.monospacedDigit())
                Text("\(record.imageCount) images \u{00B7} \(formatInterval(record.timerInterval))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview("With records") {
    NavigationStack {
        HistoryView()
    }
    .frame(width: 600, height: 500)
    .modelContainer(PreviewContainer().container)
}

#Preview("Empty") {
    NavigationStack {
        HistoryView()
    }
    .frame(width: 600, height: 500)
    .modelContainer(for: [Board.self, SessionRecord.self], inMemory: true)
}
