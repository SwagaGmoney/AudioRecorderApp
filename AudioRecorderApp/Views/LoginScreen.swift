//
//  LoginScreen.swift
//  AudioRecorderApp
//
//  Created by Yash Gandhi on 9/30/25.
//
import SwiftUI

enum Route: Hashable { case recording }

struct LoginScreen: View {
    // Navigation
    @State private var path = NavigationPath()
    // login model
    @StateObject private var loginModel = LoginScreenModel()

    // Form
    @State private var email = ""
    @State private var password = ""
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var generalError: String?
    @State private var showAlert = false

    // Rocket Animation
    @State private var showRocket = false
    @State private var rocketOffset: CGFloat = 0
    @State private var rocketOpacity: Double = 1.0

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LinearGradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.5),
                                        Color.purple.opacity(0.6), Color.purple.opacity(0.5), Color.white],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer().frame(height: 80)

                    Image("Background")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .padding(.bottom, 30)

                    VStack(alignment: .leading, spacing: 8) {
                        // Email Field
                        Text("Email").foregroundColor(.black).font(.headline)
                        HStack {
                            Image(systemName: "envelope").foregroundColor(.blue)
                            TextField("Enter Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding().background(Color.white.opacity(0.2)).cornerRadius(10)
                        if let emailError = emailError { Text(emailError).foregroundColor(.red).font(.caption) }

                        // Password Field
                        Text("Password").foregroundColor(.black).font(.headline)
                        HStack {
                            Image(systemName: "lock").foregroundColor(.blue)
                            SecureField("Enter Password", text: $password)
                        }
                        .padding().background(Color.white.opacity(0.2)).cornerRadius(10)
                        if let passwordError = passwordError { Text(passwordError).foregroundColor(.red).font(.caption) }
                    }

                    // Login Button + Rocket
                    ZStack {
                        Button {
                            Task {
                                await loginModel.login(email: email, password: password)
                                
                                if loginModel.isLoggedIn {
                                    animateRocketNavigate()
                                } else {
                                    generalError = "Invalid email or password"
                                    showAlert = true
                                }
                            }
                        } label: {
                            HStack {
                                if loginModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    Spacer()
                                } else {
                                    Text("Login")
                                        .bold()
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                        }
                        .disabled(loginModel.isLoading)


                        if showRocket {
                            Image(systemName: "paperplane.fill")
                                .resizable().scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.orange)
                                .offset(x: rocketOffset)
                                .opacity(rocketOpacity)
                                .padding(.leading, 16)
                        }
                    }

                    Spacer()
                }
                .padding(30)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Login Error"),
                          message: Text(generalError ?? "Something went wrong"),
                          dismissButton: .default(Text("OK")))
                }
            }
            .navigationDestination(for: Route.self) { _ in
                RecordingScreen()
                    .environmentObject(loginModel)
            }
            .environmentObject(loginModel)
        }
    }

    @MainActor
    func animateRocketNavigate()  {
        showRocket = true; rocketOffset = 0; rocketOpacity = 1.0

        withAnimation(.easeOut(duration: 1.2)) {
            rocketOffset = UIScreen.main.bounds.width / 3
            rocketOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2){
            showRocket = false
            path.append(Route.recording)
        }
    }
}
