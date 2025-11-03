//
//  ApiModels.swift
//  AudioRecorderApp
//
//  Created by Yash Gandhi on 10/1/25.
//

import Foundation

// Login

struct LoginRequest: Codable{
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let success: Bool
    let data: Session?
}

// session
struct SessionRequest: Codable {
    let name: String
    let condition: String
}

struct SessionResponse: Codable{
    let success: Bool
    let data: SessionData
}

// upload job
struct EmptyRequest: Codable {}

struct CreateJobResponse: Codable {
    let success: Bool
    let data: JobData?
}

struct JobData: Codable {
    let jobId: String
}

// upload file
struct UploadResponse: Codable {
    let success: Bool
    let data: UploadData
}
struct UploadData: Codable {
    let jobId: String
    let createdJob: CreatedJob
   
}
struct CreatedJob: Codable {
    let name: String
    let data: CreatedJobData
    let opts: CreatedJobOpts?
    let id: String?
    let progress: Int?
    let returnvalue: String?
    let stacktrace: String?
    let priority: Int?
    let attemptsStarted: Int?
    let attemptsMade: Int?
    let timestamp: Int?
    let queueQualifiedName: String?
}

struct CreatedJobData: Codable {
    let sessionId: String
    let userId: String
    let file: UploadedFile
    let jobId: String
}

struct UploadedFile: Codable {
    let fieldname: String
    let originalname: String
    let encoding: String
    let mimetype: String
    let destination: String
    let filename: String
    let path: String
    let size: Int
}

struct CreatedJobOpts: Codable {
    let attempts: Int?
}
