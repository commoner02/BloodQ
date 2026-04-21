//
//  ModernAuthView.swift
//  BloodQ
//

import SwiftUI

struct ModernAuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.red.opacity(0.08), Color.pink.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 55))
                                .foregroundColor(.red)
                            
                            Text(isSignUp ? "Create Account" : "Welcome Back")
                                .font(.system(size: 28, weight: .bold))
                            
                            Text(isSignUp ? "Join BloodQ to save lives" : "Sign in to continue")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 30)
                        .padding(.bottom, 10)
                        
                        // Form Fields
                        VStack(spacing: 16) {
                            if isSignUp {
                                CustomTextField(
                                    icon: "person.fill",
                                    placeholder: "Full Name",
                                    text: $name
                                )
                                .textContentType(.name)
                                .autocapitalization(.words)
                            }
                            
                            CustomTextField(
                                icon: "envelope.fill",
                                placeholder: "Email",
                                text: $email
                            )
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            
                            CustomTextField(
                                icon: "lock.fill",
                                placeholder: "Password",
                                text: $password,
                                isSecure: true
                            )
                            .textContentType(isSignUp ? .newPassword : .password)
                            
                            if isSignUp {
                                CustomTextField(
                                    icon: "lock.fill",
                                    placeholder: "Confirm Password",
                                    text: $confirmPassword,
                                    isSecure: true
                                )
                                .textContentType(.newPassword)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Forgot Password
                        if !isSignUp {
                            Button(action: { showForgotPassword = true }) {
                                Text("Forgot Password?")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            .padding(.top, -6)
                        }
                        
                        // Action Button
                        Button(action: handleAuth) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUp ? "Sign Up" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color.red, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.red.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(!isFormValid || authViewModel.isLoading)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Toggle Sign In/Up
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    isSignUp.toggle()
                                    clearFields()
                                }
                            }) {
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.top, 16)
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {
                    if alertTitle == "Success" && !isSignUp {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
    
    var isFormValid: Bool {
        let emailValid = !email.isEmpty && email.contains("@")
        let passwordValid = password.count >= 6
        
        if isSignUp {
            return !name.isEmpty && emailValid && passwordValid && password == confirmPassword
        } else {
            return emailValid && passwordValid
        }
    }
    
    func handleAuth() {
        if isSignUp {
            authViewModel.signUp(email: email, password: password, name: name) { success, error in
                if success {
                    alertTitle = "Success"
                    alertMessage = "Account created successfully!"
                    showAlert = true
                } else {
                    alertTitle = "Sign Up Failed"
                    alertMessage = error ?? "Unknown error occurred"
                    showAlert = true
                }
            }
        } else {
            authViewModel.signIn(email: email, password: password) { success, error in
                if success {
                    dismiss()
                } else {
                    alertTitle = "Sign In Failed"
                    alertMessage = error ?? "Invalid email or password"
                    showAlert = true
                }
            }
        }
    }
    
    func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        name = ""
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)
    }
}

// Forgot Password View
struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "key.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.red)
                    .padding(.top, 50)
                
                Text("Reset Password")
                    .font(.title2.bold())
                
                Text("Enter your email address")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)
                
                Button(action: resetPassword) {
                    Text("Send Reset Link")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(email.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {
                    if alertTitle == "Success" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    func resetPassword() {
        authViewModel.resetPassword(email: email) { success, message in
            alertTitle = success ? "Success" : "Error"
            alertMessage = message ?? ""
            showAlert = true
        }
    }
}

#Preview {
    ModernAuthView()
        .environmentObject(AuthViewModel())
}
