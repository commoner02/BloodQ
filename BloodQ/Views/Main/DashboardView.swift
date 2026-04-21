//
//  DashboardView.swift
//  BloodQ
//

import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var donorViewModel: DonorViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAddDonation = false
    
    var donor: Donor? {
        donorViewModel.currentDonor
    }
    
    var daysUntilEligible: Int {
        guard let nextDate = donor?.nextEligibleDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    profileSection
                    eligibilityCard
                    statsSection
                    donationHistorySection
                }
                .padding(.vertical)
            }
            .background(Color.gray.opacity(0.05).ignoresSafeArea())
            .navigationTitle("Dashboard")
            .onAppear {
                if let userId = authViewModel.user?.uid {
                    donorViewModel.fetchDonorProfile(userId: userId)
                }
            }
            .sheet(isPresented: $showAddDonation) {
                AddDonationView()
            }
        }
    }
    
    private var profileSection: some View {
        NavigationLink(destination: ProfileView()) {
            HStack(spacing: 15) {
                Circle()
                    .fill(LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(donor?.name.prefix(1) ?? "U"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(donor?.name ?? "User Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(donor?.bloodGroup ?? "Blood Group")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    Text(donor?.email ?? "email@example.com")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
    
    private var eligibilityCard: some View {
        VStack(spacing: 15) {
            if donor?.canDonate ?? false {
                eligibleContent
            } else {
                notEligibleContent
            }
        }
        .padding(.horizontal)
    }
    
    private var eligibleContent: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("You're Eligible!")
                .font(.title2.bold())
            
            Text("You can donate blood now")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            LinearGradient(colors: [.green.opacity(0.1), .green.opacity(0.05)], startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(20)
    }
    
    private var notEligibleContent: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(90 - daysUntilEligible) / 90)
                    .stroke(
                        LinearGradient(colors: [.red, .pink], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(daysUntilEligible)")
                        .font(.system(size: 36, weight: .bold))
                    Text("days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Until Next Donation")
                .font(.headline)
            
            if let nextDate = donor?.nextEligibleDate {
                Text(nextDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    private var statsSection: some View {
        HStack(spacing: 15) {
            StatCard(icon: "drop.fill", title: "Total Donations", value: "\(donor?.totalDonations ?? 0)", color: .red)
            StatCard(icon: "heart.fill", title: "Lives Saved", value: "\((donor?.totalDonations ?? 0) * 3)", color: .pink)
        }
        .padding(.horizontal)
    }
    
    private var donationHistorySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Donation History")
                    .font(.title3.bold())
                
                Spacer()
                
                Button(action: {
                    showAddDonation = true
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
                }
            }
            
            if let history = donor?.donationHistory, !history.isEmpty {
                ForEach(history) { record in
                    DonationRecordRow(record: record)
                }
            } else {
                emptyHistoryView
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10)
        .padding(.horizontal)
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No donation history yet")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(value)
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

struct DonationRecordRow: View {
    let record: DonationRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(record.date, style: .date)
                    .font(.subheadline.bold())
                Text(record.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let notes = record.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "drop.fill")
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct AddDonationView: View {
    @EnvironmentObject var donorViewModel: DonorViewModel
    @Environment(\.dismiss) var dismiss
    @State private var donationDate = Date()
    @State private var location = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Donation Details") {
                    DatePicker("Date", selection: $donationDate, displayedComponents: .date)
                    TextField("Location (e.g., Red Crescent)", text: $location)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section {
                    Button(action: saveDonation) {
                        if donorViewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Save Donation")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.red)
                    .disabled(location.isEmpty || donorViewModel.isLoading)
                }
            }
            .navigationTitle("Add Donation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    func saveDonation() {
        donorViewModel.addDonationRecord(
            date: donationDate,
            location: location,
            notes: notes.isEmpty ? nil : notes
        ) { success in
            if success {
                dismiss()
            }
        }
    }
}
