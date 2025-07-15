import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var name = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("Create Account")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Join CoachVision today")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Form fields
                VStack(spacing: 16) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        TextField("Enter your full name", text: $name)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(.name)
                    }
                    
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        HStack {
                            if showPassword {
                                TextField("Enter your password", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.newPassword)
                            }
                            
                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // Confirm Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        HStack {
                            if showConfirmPassword {
                                TextField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.newPassword)
                            }
                            
                            Button(action: {
                                showConfirmPassword.toggle()
                            }) {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Password validation
                if !password.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password must contain:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: password.count >= 8 ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(password.count >= 8 ? .green : .gray)
                                .font(.caption)
                            Text("At least 8 characters")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Password match validation
                if !confirmPassword.isEmpty && password != confirmPassword {
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                // Error message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                // Sign up button
                Button(action: {
                    Task {
                        await authManager.register(email: email, name: name, password: password)
                    }
                }) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Text("Create Account")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(25)
                }
                .disabled(authManager.isLoading || !isFormValid)
                .opacity(isFormValid ? 1.0 : 0.6)
                .padding(.horizontal, 20)
                
                // Terms and conditions
                Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Spacer(minLength: 100)
            }
        }
        .background(Color.black)
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !name.isEmpty && 
        !password.isEmpty && 
        !confirmPassword.isEmpty && 
        password == confirmPassword && 
        password.count >= 8
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthenticationManager())
        .preferredColorScheme(.dark)
} 