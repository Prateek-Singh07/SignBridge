//
//  ContentView.swift
//  SignBridge_1
//
//  Created by KIET2 on 23/10/26.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var auth = AuthManager.shared

    var body: some View {
        Group {
            if auth.isAuthenticated {
                NavigationStack {
                    DashboardView()
                }
                .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(settings.appearanceMode.colorScheme)
        .dynamicTypeSize(settings.textSize.dynamicTypeSize)
        .id(settings.textSize)
    }
}

#Preview {
    ContentView()
}
