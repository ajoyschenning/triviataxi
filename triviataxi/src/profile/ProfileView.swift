//
//  ProfileView.swift
//  triviataxi
//

internal import Combine
import FirebaseAuth
import MapboxMaps
import SwiftUI
import FirebaseStorage


struct SessionRow: View {
    let session: TriviaSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.date)
                    .font(.system(size: 14, weight: .bold))
                
                HStack(spacing: 4) {
                    Image(systemName: "road.lanes")
                    Text("\(String(format: "%.1f", session.miles)) mi")
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("+\(String(format: "%.2f", Double(session.coins)))")
                    .font(.system(.subheadline, design: .monospaced))
                    .bold()
                    .foregroundColor(.green)
                
                if session.wasPerfect {
                    Text("PERFECT")
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.yellow)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}


struct ProfileView: View {
    @State var userManager: UserManager // Passed in or fetched
    @State private var isEditing = false
    
    var body: some View {
        var user = userManager.userProfile
        
        VStack(spacing: 25) {
            // Header: Avatar & Name
            VStack(spacing: 12) {
                AsyncImage(url: URL(string: user?.avatarUrl ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black, lineWidth: 2))
                
                Text(user?.username ?? "")
                    .font(.system(size: 24, weight: .bold))
                
                Text(user?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Stats Grid
            HStack(spacing: 20) {
                StatBox(title: "MILES", value: String(format: "%.1f", user?.miles ?? 0.0))
                StatBox(title: "COINS", value: "\(user?.coins ?? 0)")
                StatBox(title: "GAMES", value: "\(user?.lifetimeGames ?? 0)")
            }
            .padding(.horizontal)
            
            FancyButton(title: "EDIT PROFILE") {
                isEditing = true
            }
            
            Spacer()

            VStack(alignment: .leading) {
                Text("RECENT TRIPS")
                    .font(.system(size: 14, weight: .black))
                    .padding(.horizontal)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 15) {
                        if userManager.sessions.isEmpty {
                                    Text("No trips yet. Start driving!")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(userManager.sessions) { session in
                                        SessionRow(session: session)
                                            .frame(width: 280)
                                    }
                                }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
        }
        .padding(25)
        .padding(.top, 40)
        .background(Color.backgroundYellow.ignoresSafeArea())
        .sheet(isPresented: $isEditing) {
            EditProfileView(userManager: $userManager)
        }
    }
}


import PhotosUI // 🚀 Needed for the picker

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var userManager: UserManager
    
    // 📸 Photo States
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImage: Image? = nil
    @State private var isUploading = false
    private func uploadImage(data: Data) async {
       // 🚀 Check 1: Ensure we have a user
       guard let currentUser = Auth.auth().currentUser else {
           print("🚨 No user found. Try logging out and back in.")
           return
       }
       
       let realUserId = currentUser.uid
       isUploading = true
       
       // 🚀 Check 2: Use the exact bucket URL to avoid "default bucket" confusion
       let storage = Storage.storage(url: "gs://trivia-taxi.firebasestorage.app")
       let storageRef = storage.reference()
       let photoRef = storageRef.child("avatars/\(realUserId).jpg")
       
       do {
           // Upload the data
           let _ = try await photoRef.putDataAsync(data)
           
           // Get the URL to save to your FastAPI backend
           let url = try await photoRef.downloadURL()
           
           try await NetworkService.shared.updateUserProfile(username: currentUser.displayName ?? "", avatarUrl: url.absoluteString)
        
           
           await MainActor.run {
                           let newUrl = url.absoluteString
                           self.userManager.userProfile?.avatarUrl = newUrl // Updates the Home screen
                           print("✅ Global and local state synced!")
                       }

           print("✅ Profile picture updated!")
           
       } catch {
           print("🚨 Upload error: \(error.localizedDescription)")
       }
       isUploading = false
        
   }
    
    

    var body: some View {
        let user = userManager.userProfile
        let usernameBinding = Binding<String>(
            get: { userManager.userProfile?.username ?? "" },
            set: { newValue in
                if userManager.userProfile == nil {
                    // If needed, initialize a default profile here; otherwise just ignore
                }
                userManager.userProfile?.username = newValue
            }
        )
        NavigationStack {
            VStack(spacing: 20) {
                // 🚀 The Image Preview / Button
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    if let profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        // 1. Convert picked item to an Image for the UI
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            profileImage = Image(uiImage: uiImage)
                            
                            // 2. Upload to Firebase
                            await uploadImage(data: data)
                        }
                    }
                }
                
                Text("Tap photo to change")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Form {
                    Section("Username") {
                        TextField("Username", text: usernameBinding)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.system(.title2, design: .monospaced))
                .bold()
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }
}


