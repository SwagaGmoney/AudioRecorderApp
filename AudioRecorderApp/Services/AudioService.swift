//
//  AudioService.swift
//  AudioRecorderApp
//
//  Created by Yash Gandhi on 10/16/25.
//

import Combine
import SwiftUI
import AVFoundation

// for audio recorder

#if canImport(UIKit)
import UIKit // For feedback
#endif
import AudioToolbox // For lightweight sound systems


//  AudioPlayer

final class AudioPlayer: ObservableObject {
    @Published var isPlaying = false
    
    @Published var progress: Double = 0
    
    private var player: AVAudioPlayer?
    
    private var timer: AnyCancellable?
    
    private var currentURL: URL?
    
    func play(_ url: URL?) {
        guard let url else { return }
        
        if isPlaying, currentURL == url {
            pause()
            return
        }
        
        stop()
        
        do {

            player = try AVAudioPlayer(contentsOf: url)
            currentURL = url
            
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
            
            
            startUpdatingProgress()
        } catch {
            print("Playback failed:", error)
            isPlaying = false
        }
    }
    
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopUpdatingProgress()
    }
    
    
    func stop() {
        player?.stop()
        isPlaying = false
        progress = 0
        stopUpdatingProgress()
        player = nil
        currentURL = nil
    }
    
    
    func seek(to prog: Double) {
        guard let player, player.duration > 0 else { return }
        player.currentTime = prog * player.duration
        progress = prog
    }
    
    
    private func startUpdatingProgress() {
        stopUpdatingProgress()
        
        timer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let player = self.player else { return }
                
                if player.isPlaying {
                    
                    self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
                } else {
                    self.isPlaying = false
                    self.stopUpdatingProgress()
                }
            }
    }
    
    private func stopUpdatingProgress() {
        timer?.cancel()
        timer = nil
    }
    
    var isPaused: Bool {
        player != nil && !isPlaying && progress > 0 && progress < 1
    }
    
    var playingURL: URL? { currentURL }
}


//  <--------------------------------------->---------------------------------------------------------<------------------------->


// Audio Recorder

final class AudioRecorder: ObservableObject {
    
    @Published var isRecording = false
    
    @Published var meterLevel: Float = 0
    
    @Published var meterHistory: [Float] = []
    
    var meterInterval: TimeInterval = 0.05
    var maxHistoryCount: Int = 80
    
    private var recorder: AVAudioRecorder?
    
    private var meterTimer: AnyCancellable?
    
    private(set) var fileURL: URL?
    
    // microphone permission
    func requestPermission(_ done: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { ok in
                DispatchQueue.main.async { done(ok) }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { ok in
                DispatchQueue.main.async { done(ok) }
            }
        }
    }
    // start recording
    func start() {
        do {
           
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            let dir = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("Recordings", isDirectory: true)
            
           
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            
            let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
            let url = dir.appendingPathComponent("\(stamp).m4a")
            fileURL = url
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            playStartFeedback()
            isRecording = true
            
           
            startMetering()
        } catch {
           
            print("Start failed:", error)
        }
    }
    
   
    func stop() {
        stopMetering()
        recorder?.stop()
        playStopFeedback()
        isRecording = false 
        recorder = nil
    }
    
    // Metering
    

    private func startMetering() {

        meterTimer?.cancel()
    
        meterTimer = Timer.publish(every: meterInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let rec = self.recorder, rec.isRecording else { return }
                rec.updateMeters()
                
               
                let power = rec.averagePower(forChannel: 0)
                self.meterLevel = Self.normalize(power)
                self.meterHistory.append(self.meterLevel)
                
                if self.meterHistory.count > self.maxHistoryCount {
                    self.meterHistory.removeFirst(self.meterHistory.count - self.maxHistoryCount)
                }
            }
    }
    
   
    private func stopMetering() {
        meterTimer?.cancel()
        meterTimer = nil
        meterLevel = 0
        meterHistory.removeAll()
    }
    
   
    private static func normalize(_ db: Float) -> Float {
        let floor: Float = -60
        if db <= floor { return 0 }
        let clamped = max(min(db, 0), floor)
        return (clamped - floor) / -floor
    }
    
    private func playStartFeedback() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        AudioServicesPlaySystemSound(1113)
    }
    
    private func playStopFeedback() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
        AudioServicesPlaySystemSound(1114)
    }
}

