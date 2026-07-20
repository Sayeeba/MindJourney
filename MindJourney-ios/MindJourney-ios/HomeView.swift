import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Welcome Back, Zahin!")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("How are you feeling today?")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                // Mood Tracker Quick Action
                VStack(alignment: .leading) {
                    Text("Daily Mood Tracking")
                        .font(.headline)
                    HStack {
                        ForEach(["😢", "😕", "😐", "🙂", "😁"], id: \.self) { emoji in
                            Button(action: { print("\(emoji) tapped") }) {
                                Text(emoji)
                                    .font(.system(size: 40))
                            }
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                }
                .padding(.horizontal)
                
                // Feature Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    FeatureCard(title: "Smart Journal", icon: "book.fill", color: .purple)
                    FeatureCard(title: "AI Assistant", icon: "sparkles", color: .blue)
                    FeatureCard(title: "Wellness Challenges", icon: "star.fill", color: .orange)
                    FeatureCard(title: "Analytics Dashboard", icon: "chart.bar.fill", color: .green)
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationBarBackButtonHidden(true) // Hide back button after login
    }
}

// Reusable component for the feature grid
struct FeatureCard: View {
    var title: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .padding(.bottom, 5)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}//
//  HomeView.swift
//  MindJourney-ios
//
//  Created by Kazi  Sayeeba Islam on 7/20/26.
//

