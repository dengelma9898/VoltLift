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

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.l) {
                // Header: VoltLift Wortmarke
                Text(String(localized: "brand.voltlift"))
                    .font(DesignSystem.Typography.titleL)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, DesignSystem.Spacing.l)

                // Aktionen: Strength / Outdoor (ohne Container, volle Breite)
                VStack(spacing: DesignSystem.Spacing.m) {
                    NavigationLink(String(localized: "action.strength")) {
                        StrengthPlansView()
                    }
                    .buttonStyle(VLPrimaryButtonStyle())

                    Button(String(localized: "action.outdoor")) {
                        // späterer Flow: Auswahl/Setup
                    }
                    .buttonStyle(VLPrimaryButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            .vlBrandBackground()
            .onAppear { WatchConnectivityService.shared.activateSession() }
        }
    }
}

#Preview {
    ContentView()
}
