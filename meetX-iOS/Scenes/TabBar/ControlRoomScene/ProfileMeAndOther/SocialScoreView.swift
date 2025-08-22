//
//  SocialScore.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 17-08-2025.
//

import SwiftUI

struct SocialScoreView: View {
    let socialScore: SocialScore?
    let heperFunction = HelperFunctions()
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView

            if isExpanded {
                expandedContentView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.pink.opacity(0.2), Color.blue.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isExpanded)
    }
}

// MARK: - Header View
extension SocialScoreView {
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Social Score")
                        .fontStyle(size: 18, weight: .semibold)
                        .foregroundStyle(ThemeManager.foregroundColor)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.gray)
                }

                if let totalScore = socialScore?.totalScore {
                    HStack(alignment: .bottom, spacing: 8) {
                        Text("\(totalScore)")
                            .fontStyle(size: 36, weight: .heavy)
                            .foregroundStyle(ThemeManager.gradientNewPinkBackground)

                        if let rankLabel = socialScore?.rankLabel {
                            Text(rankLabel)
                                .fontStyle(size: 16, weight: .medium)
                                .foregroundStyle(.gray)
                                .padding(.bottom, 4)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Expanded Content
extension SocialScoreView {
    private var expandedContentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Divider()
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 16) {
                // Category Breakdown
                if let categoryBreakdown = socialScore?.categoryBreakdown {
                    categoryBreakdownView(categoryBreakdown)
                }

                // Detailed Breakdowns
                detailedBreakdownsView

                // Tips Section
                if let tips = socialScore?.tips, !tips.isEmpty {
                    tipsView(tips)
                }

                // Last Updated
                if let lastUpdated = socialScore?.lastUpdated {
                    lastUpdatedView(lastUpdated)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func categoryBreakdownView(_ breakdown: CategoryBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .fontStyle(size: 16, weight: .semibold)
                .foregroundStyle(ThemeManager.foregroundColor)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 12) {
                categoryScoreItem("Profile", score: breakdown.profile, icon: "person.crop.circle")
                categoryScoreItem("Activity", score: breakdown.activity, icon: "figure.run")
                categoryScoreItem("Consistency", score: breakdown.consistency, icon: "calendar.badge.checkmark")
                categoryScoreItem("Behavior", score: breakdown.behavior, icon: "heart.circle")
                categoryScoreItem("Network", score: breakdown.network, icon: "person.2.circle")
            }
        }
    }

    private func categoryScoreItem(_ title: String, score: Int?, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(ThemeManager.gradientNewPinkBackground)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontStyle(size: 12, weight: .medium)
                    .foregroundStyle(.gray)

                Text("\(score ?? 0)")
                    .fontStyle(size: 16, weight: .bold)
                    .foregroundStyle(ThemeManager.foregroundColor)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }

    private var detailedBreakdownsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Profile Breakdown
            if let profileBreakdown = socialScore?.profileBreakdown {
                detailBreakdownSection(
                    title: "Profile Details",
                    icon: "person.crop.circle.fill",
                    items: [
                        ("Profile Verified", profileBreakdown.profileVerified),
                        ("All Fields Completed", profileBreakdown.allFieldsCompleted),
                        ("Display Picture", profileBreakdown.displayPictureUploaded)
                    ]
                )
            }

            // Activity Breakdown
            if let activityBreakdown = socialScore?.activityBreakdown {
                detailBreakdownSection(
                    title: "Activity Details",
                    icon: "figure.run.circle.fill",
                    items: [
                        ("Planned Activities", activityBreakdown.plannedActivities),
                        ("Live Activities", activityBreakdown.liveActivities),
                        ("Engagement", activityBreakdown.engagement)
                    ]
                )
            }

            // Network Breakdown
            if let networkBreakdown = socialScore?.networkBreakdown {
                detailBreakdownSection(
                    title: "Network Details",
                    icon: "person.2.circle.fill",
                    items: [
                        ("Accepted Connections", networkBreakdown.acceptedConnections),
                        ("Followers", networkBreakdown.followers)
                    ]
                )
            }
        }
    }

    private func detailBreakdownSection(title: String, icon: String, items: [(String, Int?)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ThemeManager.gradientNewPinkBackground)

                Text(title)
                    .fontStyle(size: 14, weight: .semibold)
                    .foregroundStyle(ThemeManager.foregroundColor)
            }

            VStack(spacing: 6) {
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    HStack {
                        Text(item.0)
                            .fontStyle(size: 12, weight: .medium)
                            .foregroundStyle(.gray)

                        Spacer()

                        Text("\(item.1 ?? 0)")
                            .fontStyle(size: 12, weight: .bold)
                            .foregroundStyle(ThemeManager.foregroundColor)
                    }
                    .padding(.leading, 24)
                }
            }
        }
    }

    private func tipsView(_ tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.orange)

                Text("Tips to Improve")
                    .fontStyle(size: 14, weight: .semibold)
                    .foregroundStyle(ThemeManager.foregroundColor)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(tips.indices, id: \.self) { index in
                    Text(tips[index])
                        .fontStyle(size: 12, weight: .medium)
                        .foregroundStyle(ThemeManager.foregroundColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true) // allow wrapping
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(ThemeManager.gradientNewPinkBackground.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(ThemeManager.gradientNewPinkBackground, lineWidth: 0.5)
                                )
                        )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func lastUpdatedView(_ lastUpdated: String) -> some View {
        HStack {
            Spacer()

            Text(
                "Last updated: \(HelperFunctions.convertUTCToISTAndCalculateDifference(utcString: lastUpdated)?.date ?? "Today")"
            )
                .fontStyle(size: 11, weight: .light)
                .foregroundStyle(.gray)
        }
    }
}
