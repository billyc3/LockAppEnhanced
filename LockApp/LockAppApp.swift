//
//  LockApp2App.swift
//  LockApp2
//
//  Created by William Cook on 3/24/25.
//

import SwiftUI

@main
struct LockAppApp: App {
    
    // Initialize the connectivity manager
    let connectivityManager = WatchConnectivityManager.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
