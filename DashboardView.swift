import SwiftUI
import Charts

struct DashboardResponseModel: Decodable {
    let user_id: Int
    let total_logs: Int
    let graph_data: [MoodGraphPoint]
    let mood_counts: [String: Int]
    let ai_insight: String
}
struct MoodGraphPoint: Decodable, Identifiable { let id: Int; let mood: String; let score: Int; let timestamp: String }

struct DashboardView: View {
    @AppStorage("userId") private var userId = 0
    @State private var data: DashboardResponseModel?
    @State private var isLoading = true
    @State private var error = ""

    var body: some View {
        NavigationStack {
            Group {
                if isLoading { ProgressView("Analyzing your mood...") }
                else if let data { dashboard(data) }
                else { ContentUnavailableView("No data", systemImage: "chart.bar.xaxis", description: Text(error.isEmpty ? "Log a mood to start your dashboard." : error)) }
            }
            .navigationTitle("Mood Dashboard")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func dashboard(_ data: DashboardResponseModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                statRow(data)
                insight(data.ai_insight)
                chart(data.graph_data)
                breakdown(data.mood_counts)
            }.padding(20)
        }.background(AppConfig.softLavender.opacity(0.25).ignoresSafeArea())
    }

    private func statRow(_ data: DashboardResponseModel) -> some View {
        HStack(spacing: 12) {
            StatCard(title: "Mood logs", value: "\(data.total_logs)", icon: "📈")
            StatCard(title: "Top mood", value: topMood(data.mood_counts), icon: moodEmoji(topMood(data.mood_counts)))
        }
    }

    private func insight(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) { Text("🤖 Personalized insight").font(.headline).foregroundStyle(AppConfig.deepPurple); Text(text).foregroundStyle(AppConfig.muted).fixedSize(horizontal: false, vertical: true) }
            .padding(18).background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func chart(_ points: [MoodGraphPoint]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mood history").font(.headline).foregroundStyle(AppConfig.deepPurple)
            if points.isEmpty { Text("No mood logs yet.").foregroundStyle(AppConfig.muted).padding(.vertical, 30) }
            else {
                Chart(points) { point in
                    LineMark(x: .value("Time", point.timestamp), y: .value("Mood", point.score)).interpolationMethod(.catmullRom).foregroundStyle(AppConfig.deepPurple)
                    PointMark(x: .value("Time", point.timestamp), y: .value("Mood", point.score)).foregroundStyle(AppConfig.pink)
                }
                .chartYScale(domain: 1...5).frame(height: 220)
            }
        }.padding(18).background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func breakdown(_ counts: [String: Int]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequency breakdown").font(.headline).foregroundStyle(AppConfig.deepPurple)
            ForEach(counts.sorted(by: { $0.value > $1.value }), id: \.key) { mood, count in
                HStack { Text(moodEmoji(mood)).font(.title2); Text(mood).fontWeight(.semibold); Spacer(); Text("\(count)").foregroundStyle(AppConfig.muted) }
                Divider()
            }
        }.padding(18).background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func load() async {
        guard userId > 0 else { return }
        isLoading = true; defer { isLoading = false }
        do { data = try await APIClient.request("/api/dashboard/mood-graph/\(userId)") }
        catch { error = error.localizedDescription }
    }

    private func topMood(_ counts: [String: Int]) -> String { counts.max(by: { $0.value < $1.value })?.key ?? "—" }
    private func moodEmoji(_ mood: String) -> String { ["Happy":"😃","Calm":"😌","Okay":"😐","Sad":"😔","Anxious":"😰"][mood] ?? "💭" }
}

struct StatCard: View { let title: String; let value: String; let icon: String; var body: some View { VStack(alignment: .leading, spacing: 6) { Text(icon).font(.title); Text(value).font(.title3.bold()).foregroundStyle(AppConfig.deepPurple); Text(title).font(.caption).foregroundStyle(AppConfig.muted) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 16)) } }

#Preview { DashboardView() }
