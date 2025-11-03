//
//  ApiService.swift
//  AudioRecorderApp
//
//  Created by Yash Gandhi on 10/7/25.
//


import Foundation

// error handling
enum ApiError: Error, LocalizedError{
    
    case invalidURL
    case invalidCredentials
    case invalidResponse
    case serverError(String)
    case requestTimeout
    case unknownError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL connection "
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidCredentials:
            return "Incorrect Email or Password"
        case .serverError(let message):
            return message
        case .requestTimeout:
            return "Request Timed out"
        case .unknownError:
            return "Unknown Error!!"
        case .decodingError:
            return "Decoding error!"
            
        }
    }
}


final class ApiService {

    static let shared = ApiService()
    private init() {}

    public let baseURLString = "https://app.cagnea.com"
    
    
    // POST Method

    func post<T: Decodable , U: Encodable>(
        path: String ,body: U, method: String = "POST" , accessToken: String? = nil , responseType: T.Type) async throws -> T{
            guard let url = URL(string: baseURLString + path) else{ throw ApiError.invalidURL}
            
            print("POST Request:\(url.absoluteString)")
            
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.timeoutInterval = 15
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
          
            // header for bearer token
            if let token = accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            // Encode body
            do{
                request.httpBody = try JSONEncoder().encode(body)
            } catch{
                print("Encoding error:" , error)
                throw ApiError.unknownError
            }
            
            
            do{
                let(data,response) = try await URLSession.shared.data(for: request)
                
                
                guard let httpResponse = response as? HTTPURLResponse else{ throw ApiError.invalidResponse}
                
                print("httt Status: \(httpResponse.statusCode)")
                
                guard(200...299).contains(httpResponse.statusCode) else {
                    throw ApiError.serverError("Server returned status code \(httpResponse.statusCode)")
                }
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let	decodedResponse = try decoder.decode(responseType, from: data)
            
                return decodedResponse
                
            }catch let urlError as URLError where urlError.code == URLError.Code.timedOut{
                throw ApiError.requestTimeout
            }catch is DecodingError {
                throw ApiError.decodingError
            }catch{
                throw ApiError.unknownError
            }
        }
}
   
