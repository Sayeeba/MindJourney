
import SwiftUI
import Charts

struct DashboardResponseModel: Decodable {
    let user_id: String
    let total_logs: Int
    let graph_data: [MoodGraphPoint]
    let mood_counts: [String: Int]
    let ai_insight: String
}

struct MoodGraphPoint: Decodable, Identifiable {
    let id: Int
    let mood: String
    let timestamp: String
}

struct DashboardView: View {
    @State private var dashboardData: DashboardResponseModel? = nil
    @State private var isLoading = true
    @State private var userId = "user_123"

    var body: some View {
        NavigationStack {
            ZStack {
                Color("LavenderBG").opacity(0.15)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("Analyzing Mood Data...")
                        .tint(Color("DeepPurple"))
                } else if let data = dashboardData {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            
                            // AI Pattern Insight Banner
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("🤖 AI Mood Analytics")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("DeepPurple"))
                                    Spacer()
                                }
                                Text(data.ai_insight)
                                    .font(.footnote)
                                    .foregroundColor(Color("MutedText"))
                                    .lineSpacing(4)
                            }
                            .padding(18)
                            .background(Color.white)
                            .cornerRadius(18)
                            .shadow(color: Color("DeepPurple").opacity(0.08), radius: 8, x: 0, y: 4)

                            // Chart Section
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Mood History")
                                    .font(.headline)
                                    .foregroundColor(Color("DeepPurple"))

                                if data.graph_data.isEmpty {
                                    Text("No mood logs recorded yet.")
                                        .font(.caption)
                                        .foregroundColor(Color("MutedText"))
                                        .padding(.vertical, 20)
                                } else {
                                    Chart {
                                        ForEach(data.graph_data) { item in
                                            BarMark(
                                                x: .value("Time", String(item.timestamp.suffix(5))),
                                                y: .value("Mood Value", moodToScore(item.mood))
                                            )
                                            .foregroundStyle(moodToColor(item.mood))
                                            .cornerRadius(6)
                                        }
                                    }
                                    .frame(height: 180)
                                    .chartYScale(domain: 0...5)
                                    .chartYAxis {
                                        AxisMarks(values: [1, 2, 3, 4, 5]) { val in
                                            AxisValueLabel {
                                                if let intVal = val.as(Int.self) {
                                                    Text(scoreToEmoji(intVal))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(18)
                            .background(Color.white)
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)

                            // Mood Breakdown Stats
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Frequency Breakdown")
                                    .font(.headline)
                                    .foregroundColor(Color("DeepPurple"))

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(data.mood_counts.sorted(by: { $0.value > $1.value }), id: \.key) { mood, count in
                                        HStack {
                                            Text(moodToEmoji(mood))
                                                .font(.title2)
                                            VStack(alignment: .leading) {
                                                Text(mood)
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(Color("DeepPurple"))
                                                Text("\(count) logs")
                                                    .font(.caption2)
                                                    .foregroundColor(Color("MutedText"))
                                            }
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }

                        }
                        .padding(20)
                    }
                    .refreshable {
                        await fetchDashboardData()
                    }
                }
            }
            .navigationTitle("Analytics & Graph")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await fetchDashboardData()
            }
        }
    }

    private func fetchDashboardData() async {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "http://127.0.0.1:5001/api/dashboard/mood-graph/\(userId)") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let decoded = try? JSONDecoder().decode(DashboardResponseModel.self, from: data) {
                DispatchQueue.main.async {
                    self.dashboardData = decoded
                }
            }
        } catch {
            print("Failed to fetch dashboard data: \(error)")
        }
    }

    // Chart Helper Mappings
    private func moodToScore(_ mood: String) -> Int {
        switch mood {
        case "Happy": return 5
        case "Calm": return 4
        case "Okay": return 3
        case "Sad": return 2
        case "Anxious": return 1
        default: return 3
        }
    }

    private func scoreToEmoji(_ score: Int) -> String {
        switch score {
        case 5: return "😃"
        case 4: return "😌"
        case 3: return "😐"
        case 2: return "😔"
        case 1: return "😰"
        default: return "😐"
        }
    }

    private func moodToEmoji(_ mood: String) -> String {
        switch mood {
        case "Happy": return "😃"
        case "Calm": return "😌"
        case "Okay": return "😐"
        case "Sad": return "😔"
        case "Anxious": return "😰"
        default: return "💭"
        }
    }

    private func moodToColor(_ mood: String) -> Color {
        switch mood {
        case "Happy": return .yellow
        case "Calm": return .green
        case "Okay": return .blue
        case "Sad": return .indigo
        case "Anxious": return .orange
        default: return .purple
        }
    }
}
#Preview {
    DashboardView()
}
//
//  DashboardView.swift
//  MindJourney-ios
//
//  Created by Kazi  Sayeeba Islam on 8/4/26.
//
