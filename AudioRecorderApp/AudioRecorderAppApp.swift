//
//  AudioRecorderAppApp.swift
//  AudioRecorderApp
//
//  Created by Yash Gandhi on 9/30/25.
//

import SwiftUI

@main
struct AudioRecorderAppApp: App {
    
    var body: some Scene {
        WindowGroup {
            LoginScreen()
                .environmentObject(LoginScreenModel())
        }
    }
}
