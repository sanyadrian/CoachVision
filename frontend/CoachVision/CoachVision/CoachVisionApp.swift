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
    @StateObject private var planManager = TrainingPlanManager(authToken: nil)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(planManager)
                .preferredColorScheme(.dark)
                .task {
                    await authManager.initializeUserProfile()
                }
        }
    }
}
