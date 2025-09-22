//
//  ContentView.swift
//  VoltLift (Watch) Watch App
//
//  Created by Dominik Engelmann on 21.09.25.
//

import HealthKit
import SwiftUI

struct ContentView: View {
    @StateObject private var workoutService = WatchWorkoutSessionService()
    @State private var isAuthorized = false

    var body: some View {
        VStack(spacing: 12) {
            Text(String(localized: "title.workout"))
                .font(.headline)

            if self.workoutService.isRunning {
                if self.workoutService.isPaused {
                    Button(String(localized: "action.resume")) { self.workoutService.resume() }
                } else {
                    Button(String(localized: "action.pause")) { self.workoutService.pause() }
                }
                Button(String(localized: "action.stop")) { self.workoutService.stop() }
            } else {
                Button(String(localized: "action.start")) {
                    do { try self.workoutService.start(activity: .functionalStrengthTraining) } catch {}
                }
            }
        }
        .onAppear {
            Task { try? await self.workoutService.requestAuthorization()
                self.isAuthorized = true
            }
            WatchConnectivityService.shared.activateSession()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
