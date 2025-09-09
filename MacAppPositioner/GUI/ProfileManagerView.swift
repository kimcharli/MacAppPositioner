import SwiftUI
import AppKit

/**
 * ProfileManagerView provides interface for creating, editing, and managing profiles
 * 
 * This view allows users to:
 * - Create new profiles based on current monitor setup
 * - Edit existing profiles (rename, modify layout assignments)
 * - Delete profiles with confirmation
 * - Preview profile configurations
 */

struct ProfileManagerView: View {
    @State private var profiles: [String: Profile] = [:]
    @State private var showingCreateProfile = false
    @State private var showingEditProfile: String? = nil
    @State private var showingDeleteConfirmation: String? = nil
    @State private var statusMessage: String = ""
    
    private let configManager = ConfigManager()
    private let profileManager = CocoaProfileManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Profile Management")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Create New Profile") {
                    showingCreateProfile = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Profile List
            if profiles.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No Profiles Found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Create your first profile to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(profiles.keys).sorted(), id: \.self) { profileName in
                            ProfileManagementRowView(
                                profileName: profileName,
                                profile: profiles[profileName]!,
                                onEdit: { showingEditProfile = profileName },
                                onDelete: { showingDeleteConfirmation = profileName }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Status
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding()
        .onAppear {
            loadProfiles()
        }
        .sheet(isPresented: $showingCreateProfile) {
            CreateProfileView(onProfileCreated: { name in
                statusMessage = "Created profile: \(name)"
                loadProfiles()
            })
        }
        .sheet(item: Binding<EditProfileWrapper?>(
            get: { showingEditProfile.map { EditProfileWrapper(profileName: $0) } },
            set: { showingEditProfile = $0?.profileName }
        )) { wrapper in
            if let profile = profiles[wrapper.profileName] {
                EditProfileView(
                    profileName: wrapper.profileName,
                    profile: profile,
                    onProfileUpdated: { name in
                        statusMessage = "Updated profile: \(name)"
                        loadProfiles()
                    }
                )
            }
        }
        .alert("Delete Profile", isPresented: .constant(showingDeleteConfirmation != nil)) {
            Button("Cancel", role: .cancel) {
                showingDeleteConfirmation = nil
            }
            Button("Delete", role: .destructive) {
                if let profileName = showingDeleteConfirmation {
                    deleteProfile(profileName)
                }
                showingDeleteConfirmation = nil
            }
        } message: {
            Text("Are you sure you want to delete the profile '\(showingDeleteConfirmation ?? "")'? This action cannot be undone.")
        }
    }
    
    private func loadProfiles() {
        switch AppUtils.loadProfiles() {
        case .success(let profilesDict):
            profiles = profilesDict
            statusMessage = "Loaded \(profiles.count) profile(s)"
        case .failure(let error):
            statusMessage = error.localizedDescription
        }
    }
    
    private func deleteProfile(_ profileName: String) {
        guard var config = configManager.loadConfig() else {
            statusMessage = "Error: could not load config.json"
            return
        }
        
        config.profiles.removeValue(forKey: profileName)
        
        if configManager.saveConfig(config) {
            statusMessage = "Deleted profile: \(profileName)"
            loadProfiles()
        } else {
            statusMessage = "Error: could not save config.json"
        }
    }
}

/**
 * Individual profile management row
 */
struct ProfileManagementRowView: View {
    let profileName: String
    let profile: Profile
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profileName)
                        .font(.headline)
                    
                    Text("\(profile.monitors.count) monitor(s)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Edit") {
                        onEdit()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Delete") {
                        onDelete()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
            }
            
            // Monitor summary
            HStack(spacing: 8) {
                ForEach(Array(profile.monitors.enumerated()), id: \.offset) { index, monitor in
                    MonitorBadgeView(monitor: monitor)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

/**
 * Small monitor badge component
 */
struct MonitorBadgeView: View {
    let monitor: Monitor
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: monitor.resolution == "macbook" ? "laptopcomputer" : "display")
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(monitor.resolution)
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Text(monitor.position)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            monitor.position == "primary" ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(monitor.position == "primary" ? Color.blue : Color.gray, lineWidth: 1)
        )
        .cornerRadius(4)
    }
}

/**
 * Wrapper for sheet binding
 */
struct EditProfileWrapper: Identifiable {
    let id = UUID()
    let profileName: String
}

/**
 * Create Profile View
 */
struct CreateProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profileName: String = ""
    @State private var statusMessage: String = ""
    
    let onProfileCreated: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Profile")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This will create a profile based on your current monitor setup")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Profile Name")
                    .font(.headline)
                
                TextField("Enter profile name", text: $profileName)
                    .textFieldStyle(.roundedBorder)
            }
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Create Profile") {
                    createProfile()
                }
                .buttonStyle(.borderedProminent)
                .disabled(profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    private func createProfile() {
        let trimmedName = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            statusMessage = "Please enter a profile name"
            return
        }
        
        guard var config = ConfigManager().loadConfig() else {
            statusMessage = "Error: could not load config.json"
            return
        }
        
        if config.profiles[trimmedName] != nil {
            statusMessage = "Error: a profile with this name already exists"
            return
        }
        
        let monitors = CocoaCoordinateManager.shared.getAllMonitors().map { monitor -> Monitor in
            let position: String
            if monitor.isBuiltIn {
                position = "builtin"
            } else if monitor.isWorkspace {
                position = "workspace"
            } else {
                position = "secondary"
            }
            return Monitor(resolution: monitor.resolution, position: position)
        }
        
        let newProfile = Profile(monitors: monitors)
        config.profiles[trimmedName] = newProfile
        
        if ConfigManager().saveConfig(config) {
            onProfileCreated(trimmedName)
            dismiss()
        } else {
            statusMessage = "Error: could not save config.json"
        }
    }
}

/**
 * Edit Profile View
 */
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var newProfileName: String
    let originalProfileName: String
    let profile: Profile
    let onProfileUpdated: (String) -> Void
    
    init(profileName: String, profile: Profile, onProfileUpdated: @escaping (String) -> Void) {
        self.originalProfileName = profileName
        self._newProfileName = State(initialValue: profileName)
        self.profile = profile
        self.onProfileUpdated = onProfileUpdated
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Profile: \(originalProfileName)")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Profile Name")
                    .font(.headline)
                
                TextField("Enter new profile name", text: $newProfileName)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Save Changes") {
                    updateProfileName()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 200)
    }
    
    private func updateProfileName() {
        let trimmedName = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, trimmedName != originalProfileName else {
            return
        }
        
        guard var config = ConfigManager().loadConfig() else {
            // Handle error
            return
        }
        
        config.profiles.removeValue(forKey: originalProfileName)
        config.profiles[trimmedName] = profile
        
        if ConfigManager().saveConfig(config) {
            onProfileUpdated(trimmedName)
            dismiss()
        } else {
            // Handle error
        }
    }
}

// MARK: - Preview

struct ProfileManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileManagerView()
    }
}