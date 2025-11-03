//
//  RecordingScreen.swift
//  AudioRecorderApp
//

import SwiftUI
import AVFoundation
import Combine
#if canImport(UIKit)
import UIKit
#endif
	
struct RecordingScreen: View {
    
    @EnvironmentObject var loginModel: LoginScreenModel
    @Environment(\.colorScheme) private var systemColorScheme
    
    @StateObject private var rec = AudioRecorder()
    @StateObject private var player = AudioPlayer()
    
    @State private var recordings: [URL] = []
    @State private var micDenied = false
    
    @State private var selectedRecording: URL? = nil
    @State private var navigateToUpload = false
    
    @State private var useDarkMode = true
    
    var body: some View {
        ZStack {
            LinearGradient(
                    gradient: Gradient(colors: useDarkMode
                                       ? [Color(red: 0.08, green: 0.08, blue: 0.1), Color(red: 0.0, green: 0.0, blue: 0.05)]
                                       : [Color(.systemGray6), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: useDarkMode)
            
            VStack(spacing: 24) {
                
                HStack {
                    Text("Cagnea Recorder")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(useDarkMode ? .white : .black)
                    
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(useDarkMode ? Color.white.opacity(0.1) : Color.white)
                            .shadow(color: useDarkMode ? .clear : .gray.opacity(0.25), radius: 5, x: 0, y: 2)
                            .frame(width: 60, height: 34)
                            .overlay(
                                Toggle(isOn: $useDarkMode) {
                                    Image(systemName: useDarkMode ? "moon.fill" : "sun.max.fill")
                                        .imageScale(.large)
                                        .foregroundColor(useDarkMode ? .yellow : .orange)
                                }
                                .labelsHidden()
                                .tint(.blue)
                                .padding(.horizontal, 6)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                VStack(spacing: 8) {
                    WaveformView(values: rec.meterHistory, barCount: 24)
                        .frame(height: 54)
                        .padding(.horizontal)
                    
                    ProgressView(value: rec.meterLevel)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                        .frame(height: 8)
                        .padding(.horizontal)
                        .animation(.linear(duration: 0.05), value: rec.meterLevel)
                }
                
                HStack(spacing: 12) {
                    Button(rec.isRecording ? "Stop" : "Record") {
                        playTapHaptic()
                        if rec.isRecording {
                            rec.stop()
                        } else {
                            player.stop()
                            rec.start()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Play") {
                        playTapHaptic()
                        player.play(rec.fileURL)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(rec.isRecording || rec.fileURL == nil)
                }
                
                
                if let url = rec.fileURL {
                    Text("File: \(url.lastPathComponent)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recordings")
                        .font(.headline)
                        .foregroundColor(useDarkMode ? .white : .black)
                        .padding(.leading)
                    
                    List {
                        ForEach(recordings, id: \.self) { url in
                            HStack(spacing: 8) {
                                Text(url.lastPathComponent)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(selectedRecording == url ? .blue : (useDarkMode ? .white : .black))
                                    .onTapGesture {
                                        playTapHaptic()
                                        selectedRecording = url
                                    }
                                
                                Button {
                                    if player.playingURL == url && player.isPlaying {
                                        player.pause()
                                    } else {
                                        player.play(url)
                                    }
                                } label: {
                                    Image(systemName: (player.playingURL == url && player.isPlaying) ? "pause.fill" : "play.fill")
                                        .foregroundColor(useDarkMode ? .white : .black)
                                }
                                .buttonStyle(.plain)
                                
                                ProgressView(value: player.playingURL == url ? player.progress : 0)
                                    .frame(width: 60)
                            }
                            .padding(.vertical, 6)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let url = recordings[index]
                                try? FileManager.default.removeItem(at: url)
                                if player.playingURL == url {
                                    player.stop()
                                }
                            }
                            recordings = recordingsList()
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(useDarkMode ? Color.white.opacity(0.05) : Color.white)
                            .shadow(color: useDarkMode ? .clear : .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    .frame(maxHeight: 260)
                }
                
                if selectedRecording != nil {
                    Button {
                        playTapHaptic()
                        navigateToUpload = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Upload Selected")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(radius: 5, y: 3)
                    }
                    .padding(.horizontal)
                    .navigationDestination(isPresented: $navigateToUpload) {
                        UploadScreen(
                            fileURL: rec.fileURL!,
                            sessionId: loginModel.currentSessionId,
                            jobId: loginModel.currentjobId,
                            accessToken: loginModel.currentAccessToken
                        )
                    }
                }
                
                Spacer()
            }
            .padding(.bottom)
        }
        
        .preferredColorScheme(useDarkMode ? .dark : .light)
        
        .task {
            rec.requestPermission { ok in
                micDenied = (ok == false)
            }
            recordings = recordingsList()
        }
        .onChange(of: rec.isRecording) { _, isRecording in
            if isRecording {
                player.stop()
            } else {
                recordings = recordingsList()
            }
        }
        .alert("Microphone Access Needed", isPresented: $micDenied) {
            Button("OK", role: .cancel) {}
            #if canImport(UIKit)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            #endif
        } message: {
            Text("Please allow microphone access in Settings to record audio.")
        }
    }
    
    
    func recordingsList() -> [URL] {
        let dir = try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Recordings", isDirectory: true)
        
        guard let dir, let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return [] }
        return files.filter { $0.pathExtension == "m4a" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
    
    private func playTapHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }
    
    private func friendlyDate(for url: URL) -> String {
        if let values = try? url.resourceValues(forKeys: [.creationDateKey]), let date = values.creationDate {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short
            return df.string(from: date)
        }
        let name = url.deletingPathExtension().lastPathComponent
        return name.replacingOccurrences(of: "T", with: " ")
    }
    
    @MainActor
    func audioDurationString(for url: URL) async -> String {
        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            guard seconds.isFinite, seconds > 0 else { return "—" }
            let s = Int(seconds.rounded())
            let mPart = s / 60
            let sPart = s % 60
            return String(format: "%d:%02d", mPart, sPart)
        } catch {
            print("Failed to load duration: \(error)")
            return "—"
        }
    }
}
