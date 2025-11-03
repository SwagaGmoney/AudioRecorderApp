//
//  LoginScreenModel.swift
//  AudioRecorderApp
//
//  Created by Yash Gandhi on 10/14/25.
//

import SwiftUI
import AVFoundation

@MainActor
final class LoginScreenModel: ObservableObject {
   
    @Published var isLoading = false
    @Published var isLoggedIn = false
    @Published var errorMessage: String? = nil
    
    // token storing 
    @Published var currentSessionId: String = ""
    @Published var currentjobId: String = ""
    @Published var currentAccessToken: String = ""

    private let authService: AuthService
    init(authService: AuthService = AuthService()){
        self.authService = authService
    }
    
    func login(email: String , password: String) async {
         isLoading = true
         errorMessage = nil
         defer { isLoading = false}
        
        do{
            let session = try await authService.login(email: email, password: password)
            currentAccessToken = session.accessToken
            print("accessToken: ", session.accessToken)
            isLoggedIn = true
        
            let sessionData = try await AuthService.shared.createSession(accessToken: session.accessToken)
            currentSessionId = sessionData.id
            print("session created:", sessionData.id)
            
            let jobData = try await AuthService.shared.createUploadJob(sessionId: sessionData.id, accessToken: session.accessToken)
            currentjobId = jobData.jobId
            print("Job created", jobData.jobId)
            
        }catch{
            isLoggedIn = false
            errorMessage = " Unknown Err occured"
            print("Login failed with error:", error)
        }
        
                    
    }
    

    
}
