//
//  EntryView.swift
//  SignBridge_1
//
//  Created by KIET2 on 23/10/26.
//

import SwiftUI

/// Entry wrapper that routes directly into the main DashboardView.
struct EntryView: View {
    var body: some View {
        DashboardView()
    }
}

#Preview {
    NavigationStack {
        EntryView()
    }
}
