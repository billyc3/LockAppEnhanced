//
//  LockAppApp.swift
//  LockApp Watch App
//
//  Created by William Cook on 3/26/25.
//

import SwiftUI
import AppIntents
import LockAppShared

@main
struct LockApp_Watch_AppApp: App {
    // Initialize the connectivity manager
    let connectivityManager = WatchConnectivityManager.shared
    
    init() {
        // Initialize the app lifecycle manager
        _ = WatchConnectivityManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
