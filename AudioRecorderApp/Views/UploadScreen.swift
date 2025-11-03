//
//  UploadScreen.swift
//  AudioRecorderApp
//
//  Created by Yash Gandhi on 10/27/25.
//

import SwiftUI

struct UploadScreen: View {
    let fileURL: URL
    let sessionId: String
    let jobId: String
    let accessToken: String

    @State private var isUploading = false
    @State private var progress: Double = 0
    @State private var message: String = "Ready to upload"
    @State private var showRetry = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if isUploading {
                ProgressView(message, value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
            } else {
                Text(message)
                    .font(.title3)
                    .foregroundColor(showRetry ? .red : .green)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            // Retry button
            if showRetry {
                Button("Retry") {
                    Task {
                        await startUpload()
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Uploading")
        .navigationBarBackButtonHidden(true)
        .task {
            await startUpload()
        }
    }

    @MainActor
    func startUpload() async {
        isUploading = true
        progress = 0
        showRetry = false
        message = "Uploading..."
        
        print(" Starting upload for file: \(fileURL.lastPathComponent)")

        do {
            let responseData = try await UploadService.shared.uploadFile(
                sessionId: sessionId,
                jobId: jobId,
                accessToken: accessToken,
                fileURL: fileURL
            ) { newProgress in
                DispatchQueue.main.async {
                    self.progress = newProgress
                }
            }

            // Print raw JSON response
            if let jsonString = String(data: responseData, encoding: .utf8) {
                print(" Upload Response JSON:\n\(jsonString)")
            } else {
                print(" Response not valid JSON ")
            }

            // Decode into UploadResponse
            let decoded = try JSONDecoder().decode(UploadResponse.self, from: responseData)

            // Display job info instead of message
            
            message = """
             Upload Successful!
            Job ID: \(decoded.data.jobId)
            File: \(decoded.data.createdJob.data.file.originalname)
            """

            print(" Upload successful for job: \(decoded.data.jobId)")
            
            isUploading = false
            showRetry = false

        } catch {
            // Upload failed
            message = "Upload failed: \(error.localizedDescription)"
            print(" Upload failed with error: \(error)")
            isUploading = false
            showRetry = true
        }
    }

}

