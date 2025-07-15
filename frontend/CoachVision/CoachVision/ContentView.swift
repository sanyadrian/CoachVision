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
                    // Show main dashboard
                    DashboardView()
                } else {
                    // Show profile completion
                    ProfileCompletionView()
                }
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
}
