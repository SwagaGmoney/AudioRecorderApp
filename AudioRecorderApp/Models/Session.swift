//
//  Session.swift
//  AudioRecorderApp
//
//  Created by Yash Gandhi on 10/1/25.
//

import Foundation

struct Session: Codable {
    let accessToken: String
    let expiresIn: Int
    let user: User?
}


struct SessionData: Codable , Identifiable{
    let id: String
    let userId: String?
    let name: String?
    let condition:String?
    let age: Int?
    let visitDate: String?
    let summary: String?
    let transcript: String?
    let audioUrl: String?
    let createdAt: String
    let updatedAt: String
    
}
// recording model

struct Recording: Identifiable , Hashable{
    let id = UUID()
    let url: URL
    let creationAt: Date
    let sequence: Int
    
}

