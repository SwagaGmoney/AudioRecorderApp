//
//  AuthService.swift
//  AudioRecorderApp
//
//  Created by Yash Gandhi on 10/2/25.
//
import Foundation
import CryptoKit


final class AuthService {
    static let shared = AuthService()
    
    func login(email: String, password: String) async throws -> Session {
        // request body
        let reqbody = LoginRequest(email: email, password: password)
        do {
            // api call
            
            let response = try await ApiService.shared.post(
                path: "/api/v1/auth/login",
                body: reqbody,
                responseType: LoginResponse.self
            )
            
            guard response.success, let session = response.data else {
                throw ApiError.invalidCredentials
            }
            
            return session
        } catch {
            print("Login failed with error:", error)
            throw error
        }
    }
    
    // create session
    
    func createSession(accessToken: String) async throws -> SessionData{
        // request body
        let reqbody = SessionRequest(name: "Audio Recording", condition: "Demo Recording")
        
        // api call
        let response = try await ApiService.shared.post(path: "/api/v1/session", body: reqbody,accessToken: accessToken , responseType: SessionResponse.self)
       
        guard response.success else {
            throw ApiError.serverError("server return failed")
        }
        
        return response.data
        
    }
    
    // create upload jobs
    
    func createUploadJob(sessionId: String, accessToken: String) async throws -> JobData {
        let path = "/api/v1/session/\(sessionId)/create-job"
        
        let response = try await ApiService.shared.post(
            path: path,
            body: EmptyRequest(),
            accessToken: accessToken,
            responseType: CreateJobResponse.self
        )
    
        guard response.success, let jobId = response.data else {
            throw ApiError.serverError("Failed to create upload job")
        }
        
        return jobId
    }

}

// upload file

final class UploadService {
    static let shared = UploadService()
    private init() {}

    func uploadFile(
        sessionId: String,
        jobId: String,
        accessToken: String,
        fileURL: URL,
        progress: @escaping (Double) -> Void
    ) async throws -> Data {
        guard let url = URL(string: "https://app.cagnea.com/api/v1/session/\(sessionId)/upload/\(jobId)") else {
            throw URLError(.badURL)
        }

        // Read file data
        let fileData = try Data(contentsOf: fileURL)
        let checksum = SHA256.hash(data: fileData).map { String(format: "%02x", $0) }.joined()

        // Prepare multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        // 1️⃣ File Part
        let filename = fileURL.lastPathComponent
        let mimeType = "audio/m4a"

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")

        // 2️⃣ Additional Fields
        let fields: [String: String] = [
            "size": "\(fileData.count)",
            "mimetype": mimeType,
            "originalname": filename,
            "encoding": "7bit",
            "chunkIndex": "0",
            "totalChunks": "1",
            "checksum": checksum
        ]

        for (key, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        body.append("--\(boundary)--\r\n")

        // 3️⃣ Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // 4️⃣ Use an upload task with progress
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: UploadProgressDelegate(progressHandler: progress), delegateQueue: nil)

        // Use async upload
        let (data, response) = try await session.upload(for: request, from: body)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // 5️⃣ Handle status code
        if (200...299).contains(httpResponse.statusCode) {
            return data
        } else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "No error body"
            print(" Upload failed with status: \(httpResponse.statusCode), body: \(errorMessage)")
            throw URLError(.badServerResponse)
        }
    }
}

//  Progress Delegate
final class UploadProgressDelegate: NSObject, URLSessionTaskDelegate {
    let progressHandler: (Double) -> Void

    init(progressHandler: @escaping (Double) -> Void) {
        self.progressHandler = progressHandler
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        guard totalBytesExpectedToSend > 0 else { return }
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        DispatchQueue.main.async {
            self.progressHandler(progress)
        }
    }
}

//  Data helper
private extension Data {
    mutating func append(_ string: String) {
        if let d = string.data(using: .utf8) {
            self.append(d)
        }
    }
}
