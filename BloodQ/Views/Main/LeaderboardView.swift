//
//  LeaderboardView.swift
//  BloodQ
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var donorViewModel: DonorViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gray.opacity(0.05).ignoresSafeArea()
                
                if donorViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if donorViewModel.leaderboard.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Donors Yet")
                            .font(.title3.bold())
                        Text("Be the first donor!\nComplete your profile and add your first donation")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Compact Podium Section
                            CompactPodiumView(leaderboard: Array(donorViewModel.leaderboard.prefix(3)))
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            
                            // List Section Header
                            if donorViewModel.leaderboard.count > 3 {
                                HStack {
                                    Text("All Donors")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Rank")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            }
                            
                            // List View (All ranks)
                            LazyVStack(spacing: 8) {
                                ForEach(donorViewModel.leaderboard) { entry in
                                    LeaderboardListRow(entry: entry)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 30)
                    }
                    .refreshable {
                        donorViewModel.fetchLeaderboard()
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .onAppear {
                donorViewModel.fetchLeaderboard()
            }
        }
    }
}

// MARK: - Compact Podium View (Top 3 only)
struct CompactPodiumView: View {
    let leaderboard: [LeaderboardEntry]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 2nd Place (Left)
            if leaderboard.count >= 2 {
                CompactPodiumCard(
                    entry: leaderboard[1],
                    rankColor: Color.gray,
                    rankIcon: "2nd",
                    isFirst: false
                )
            }
            
            // 1st Place (Center - Highlighted)
            if leaderboard.count >= 1 {
                CompactPodiumCard(
                    entry: leaderboard[0],
                    rankColor: Color.yellow,
                    rankIcon: "1st",
                    isFirst: true
                )
            }
            
            // 3rd Place (Right)
            if leaderboard.count >= 3 {
                CompactPodiumCard(
                    entry: leaderboard[2],
                    rankColor: Color(red: 0.8, green: 0.5, blue: 0.2),
                    rankIcon: "3rd",
                    isFirst: false
                )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Compact Podium Card
struct CompactPodiumCard: View {
    let entry: LeaderboardEntry
    let rankColor: Color
    let rankIcon: String
    let isFirst: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Crown for 1st place
            if isFirst {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
            } else {
                Spacer().frame(height: 24)
            }
            
            // Profile Circle
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: isFirst ? 65 : 55, height: isFirst ? 65 : 55)
                
                Circle()
                    .stroke(rankColor, lineWidth: 2)
                    .frame(width: isFirst ? 65 : 55, height: isFirst ? 65 : 55)
                
                Text(String(entry.name.prefix(1)))
                    .font(isFirst ? .title : .title2)
                    .bold()
                    .foregroundColor(.red)
            }
            
            // Rank Badge
            Text(rankIcon)
                .font(.caption2)
                .bold()
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(rankColor)
                .cornerRadius(12)
            
            // Name
            Text(entry.name)
                .font(isFirst ? .subheadline.bold() : .caption.bold())
                .lineLimit(1)
                .frame(maxWidth: 90)
            
            // Blood Group
            Text(entry.bloodGroup)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.red)
                .cornerRadius(8)
            
            // Donations
            Text("\(entry.totalDonations)")
                .font(isFirst ? .title2.bold() : .headline.bold())
                .foregroundColor(entry.totalDonations > 0 ? .red : .gray)
            
            Text("donation\(entry.totalDonations != 1 ? "s" : "")")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isFirst ? 12 : 8)
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - Leaderboard List Row (All Ranks)
struct LeaderboardListRow: View {
    let entry: LeaderboardEntry
    
    var rankIcon: String {
        switch entry.rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(entry.rank)"
        }
    }
    
    var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .secondary
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            if entry.rank <= 3 {
                Text(rankIcon)
                    .font(.title3)
                    .frame(width: 45, alignment: .leading)
            } else {
                Text(rankIcon)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .leading)
            }
            
            // Profile Circle
            Circle()
                .fill(Color.red.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(entry.name.prefix(1)))
                        .font(.title3.bold())
                        .foregroundColor(.red)
                )
            
            // Name and Blood Group
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(entry.bloodGroup)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(6)
            }
            
            Spacer()
            
            // Donation Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.totalDonations)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(entry.totalDonations > 0 ? (entry.rank <= 3 ? .red : .primary) : .gray)
                
                Text("donation\(entry.totalDonations != 1 ? "s" : "")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            entry.rank <= 3 ?
                Color(red: 0.95, green: 0.95, blue: 0.95) :
                Color.white
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}
