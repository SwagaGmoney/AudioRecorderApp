//
//  ContentView.swift
//  AudioRecorderApp
//
//  Created by Yash Gandhi on 9/30/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var loginModel: LoginScreenModel

    var body: some View {
        NavigationStack {
            if loginModel.isLoggedIn {
                RecordingScreen()
                    .environmentObject(loginModel)
            } else {
                LoginScreen()
                    .environmentObject(loginModel) 
            }
        }
    }
}


