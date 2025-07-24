//
//  CoachVisionApp.swift
//  CoachVision
//
//  Created by Oleksandr Adrianov on 2025-07-14.
//

import SwiftUI

@main
struct CoachVisionApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var mealManager = MealManager(authToken: nil, userId: nil)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(authManager.trainingPlanManager)
                .environmentObject(mealManager)
                .preferredColorScheme(.dark)
                .task {
                    await authManager.initializeUserProfile()
                    // Update mealManager with latest auth info
                    await MainActor.run {
                        mealManager.updateAuth(token: authManager.authToken, userId: authManager.currentUser?.id)
                    }
                }
        }
    }
}
