//
//  AuthViewModel.swift
//  BloodQ
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    private let db = Firestore.firestore()
    
    init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil
    }
    
    func signUp(email: String, password: String, name: String, completion: @escaping (Bool, String?) -> Void) {
        guard validateEmail(email) else {
            completion(false, "Please enter a valid email address")
            return
        }
        
        guard validatePassword(password) else {
            completion(false, "Password must be at least 6 characters")
            return
        }
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(false, "Please enter your full name")
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false, error.localizedDescription)
                    return
                }
                
                guard let user = result?.user else {
                    completion(false, "Failed to create user")
                    return
                }
                
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = name
                changeRequest.commitChanges()
                
                self?.user = user
                self?.isAuthenticated = true
                completion(true, nil)
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard validateEmail(email) else {
            completion(false, "Please enter a valid email address")
            return
        }
        
        guard !password.isEmpty else {
            completion(false, "Please enter your password")
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false, error.localizedDescription)
                } else if let user = result?.user {
                    self?.user = user
                    self?.isAuthenticated = true
                    completion(true, nil)
                }
            }
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
        guard validateEmail(email) else {
            completion(false, "Please enter a valid email address")
            return
        }
        
        isLoading = true
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, "Password reset link sent to your email")
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func validatePassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}
