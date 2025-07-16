//
//  ContentView.swift
//  CoachVision
//
//  Created by Oleksandr Adrianov on 2025-07-14.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if let user = authManager.currentUser, user.isProfileComplete {
                    // Show main app with tab navigation
                    MainTabView()
                } else {
                    // Show profile completion
                    ProfileCompletionView()
                }
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
        .onAppear {
            print("ContentView - isAuthenticated: \(authManager.isAuthenticated)")
            print("ContentView - currentUser: \(authManager.currentUser?.name ?? "nil")")
            print("ContentView - isProfileComplete: \(authManager.currentUser?.isProfileComplete ?? false)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
}
