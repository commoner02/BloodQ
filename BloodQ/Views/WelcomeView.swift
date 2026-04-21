//
//  WelcomeView.swift
//  BloodQ
//


import SwiftUI

struct WelcomeView: View {
    @State private var showAuth = false
    @State private var animateContent = false
    @State private var currentSlide = 0
    
    let slides = [
        OnboardingSlide(
            image: "drop.fill",
            title: "Save Lives",
            description: "Connect with blood donors in your area and help save lives"
        ),
        OnboardingSlide(
            image: "person.2.fill",
            title: "Find Donors",
            description: "Search for verified donors by blood group and location"
        ),
        OnboardingSlide(
            image: "bell.fill",
            title: "Get Notified",
            description: "Receive instant notifications for blood requests nearby"
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.red.opacity(0.85), Color.pink.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .opacity(animateContent ? 1 : 0)
                    
                    Text("BloodQ")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                        .offset(y: animateContent ? 0 : 50)
                        .opacity(animateContent ? 1 : 0)
                    
                    Text("Connecting Lives")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .offset(y: animateContent ? 0 : 30)
                        .opacity(animateContent ? 1 : 0)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Slides
                TabView(selection: $currentSlide) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        SlideView(slide: slides[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 260)
                .opacity(animateContent ? 1 : 0)
                
                Spacer()
                
                // Get Started Button
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showAuth = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Get Started")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .foregroundColor(.red)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .opacity(animateContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $showAuth) {
            ModernAuthView()
        }
    }
}

struct OnboardingSlide {
    let image: String
    let title: String
    let description: String
}

struct SlideView: View {
    let slide: OnboardingSlide
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: slide.image)
                .font(.system(size: 55))
                .foregroundColor(.white)
            
            Text(slide.title)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(slide.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
