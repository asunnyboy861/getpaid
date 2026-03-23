//
//  ContactSupportView.swift
//  getpaid
//
//  Created by GetPaid on 2026/3/23.
//

import SwiftUI

enum FeedbackSubject: String, CaseIterable, Identifiable {
    case general = "General Feedback"
    case bug = "Bug Report"
    case feature = "Feature Request"
    case billing = "Billing Issue"
    case account = "Account Problem"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .general:
            return "bubble.left.fill"
        case .bug:
            return "ladybug.fill"
        case .feature:
            return "lightbulb.fill"
        case .billing:
            return "creditcard.fill"
        case .account:
            return "person.crop.circle.fill"
        case .other:
            return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .general:
            return .blue
        case .bug:
            return .red
        case .feature:
            return .yellow
        case .billing:
            return .green
        case .account:
            return .purple
        case .other:
            return .gray
        }
    }
}

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedSubject: FeedbackSubject = .general
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    private let feedbackAPIURL = "https://feedback-board.iocompile67692.workers.dev/api/feedback"
    
    var body: some View {
        NavigationStack {
            Form {
                subjectSection
                contactInfoSection
                messageSection
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for your feedback. We'll get back to you soon.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadUserInfo()
            }
        }
    }
    
    private var subjectSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FeedbackSubject.allCases) { subject in
                        SubjectButton(
                            subject: subject,
                            isSelected: selectedSubject == subject
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedSubject = subject
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        } header: {
            Text("What can we help you with?")
                .font(.headline)
                .textCase(nil)
        }
    }
    
    private var contactInfoSection: some View {
        Section("Contact Information") {
            TextField("Your Name", text: $name)
            
            TextField("Email Address", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
        }
    }
    
    private var messageSection: some View {
        Section {
            TextEditor(text: $message)
                .frame(minHeight: 120)
                .overlay(alignment: .topLeading) {
                    if message.isEmpty {
                        Text("Describe your issue or feedback here...")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
            
            Button {
                submitFeedback()
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Submit Feedback")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid || isSubmitting)
            .listRowInsets(EdgeInsets())
            .padding()
        } header: {
            Text("Message")
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func loadUserInfo() {
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? modelContext.fetch(descriptor).first {
            if !settings.businessName.isEmpty {
                name = settings.businessName
            }
            if !settings.businessEmail.isEmpty {
                email = settings.businessEmail
            }
        }
    }
    
    private func submitFeedback() {
        guard isFormValid else { return }
        
        isSubmitting = true
        
        let feedbackData: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "subject": selectedSubject.rawValue,
            "message": message.trimmingCharacters(in: .whitespacesAndNewlines),
            "app_name": "GetPaid"
        ]
        
        guard let url = URL(string: feedbackAPIURL) else {
            showError("Invalid API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: feedbackData)
        } catch {
            showError("Failed to encode feedback data")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    showError("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    showError("Invalid server response")
                    return
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    showSuccessAlert = true
                } else {
                    showError("Server error (Status: \(httpResponse.statusCode))")
                }
            }
        }.resume()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
        isSubmitting = false
    }
}

struct SubjectButton: View {
    let subject: FeedbackSubject
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: subject.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .white : subject.color)
                
                Text(subject.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? subject.color : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? subject.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContactSupportView()
        .modelContainer(AppContainer.shared.container)
}
