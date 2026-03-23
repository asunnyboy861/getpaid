//
//  DashboardView.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import SwiftData
import SwiftUI
import MessageUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?
    @State private var showMailComposer = false
    @State private var mailComposer: MFMailComposeViewController?
    @State private var selectedInvoiceForReminder: Invoice?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    pendingRemindersSection

                    overviewSection

                    needsAttentionSection

                    upcomingRemindersSection
                }
                .padding()
            }
            .navigationTitle("GetPaid")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                }
            }
            }
            .refreshable {
                viewModel?.loadData()
            }
            .sheet(isPresented: $showMailComposer) {
                if let mailComposer = mailComposer {
                    MailComposerWrapper(mailComposer: mailComposer)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = DashboardViewModel(modelContext: modelContext)
                }
                viewModel?.loadData()
            }
        }
    }

    private var pendingRemindersSection: some View {
        Group {
            if let pendingReminders = viewModel?.pendingReminders, !pendingReminders.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.orange)
                        Text("Pending Reminders")
                            .font(.headline)
                        Text("\(pendingReminders.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.orange)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }

                    ForEach(pendingReminders.prefix(3)) { reminder in
                        if let invoice = reminder.invoice, let client = invoice.client {
                            PendingReminderRow(
                                reminder: reminder,
                                invoice: invoice,
                                client: client,
                                onSend: {
                                    selectedInvoiceForReminder = invoice
                                    sendReminderForInvoice(invoice)
                                    viewModel?.dismissReminder(reminder)
                                },
                                onDismiss: {
                                    viewModel?.dismissReminder(reminder)
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Outstanding",
                    value: viewModel?.formattedTotalOutstanding ?? "$0.00",
                    color: .blue
                )
                
                StatCard(
                    title: "Overdue Amount",
                    value: viewModel?.formattedOverdueAmount ?? "$0.00",
                    color: .red
                )
                
                StatCard(
                    title: "Pending Invoices",
                    value: "\(viewModel?.pendingInvoicesCount ?? 0)",
                    color: .orange
                )
            }
        }
    }
    
    private var needsAttentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Needs Attention")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: InvoiceListView()) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            
            if let invoices = viewModel?.overdueInvoices, invoices.isEmpty {
                ContentUnavailableView(
                    "All Caught Up",
                    systemImage: "checkmark.circle",
                    description: Text("No overdue invoices")
                )
                .frame(height: 100)
            } else {
                ForEach(viewModel?.overdueInvoices.prefix(5) ?? []) { invoice in
                    InvoiceRowView(invoice: invoice) {
                        sendReminderForInvoice(invoice)
                    } onMarkPaid: {
                        viewModel?.markAsPaid(invoice)
                    }
                }
            }
        }
    }
    
    private var upcomingRemindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Reminders")
                    .font(.headline)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tomorrow")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel?.tomorrowRemindersCount ?? 0) reminders")
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel?.thisWeekRemindersCount ?? 0) reminders")
                        .font(.headline)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func sendReminderForInvoice(_ invoice: Invoice) {
        guard EmailService.shared.canSendMail() else {
            return
        }
        
        let composer = EmailService.shared.sendReminderEmail(
            invoice: invoice,
            escalationLevel: invoice.escalationLevel
        ) { result in
            switch result {
            case .success:
                Task {
                    await viewModel?.sendReminder(for: invoice)
                }
            case .failure:
                break
            }
        }
        
        if let composer = composer {
            mailComposer = composer
            showMailComposer = true
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InvoiceRowView: View {
    let invoice: Invoice
    let onSendReminder: () -> Void
    let onMarkPaid: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: statusIcon)
                            .foregroundStyle(statusColor)
                        
                        Text(invoice.invoiceNumber)
                            .font(.headline)
                    }
                    
                    Text("\(invoice.client?.name ?? "Unknown") • \(invoice.total.formatted(.currency(code: "USD")))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(invoice.daysOverdue) days overdue")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(invoice.escalationLevel.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }
            }
            
            HStack(spacing: 12) {
                Button(action: onSendReminder) {
                    Text("Send Reminder")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: onMarkPaid) {
                    Text("Mark Paid")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var statusIcon: String {
        switch invoice.status {
        case .overdue1to7: return "clock.fill"
        case .overdue8to30: return "exclamationmark.triangle.fill"
        case .overdue30plus: return "xmark.octagon.fill"
        default: return "doc.fill"
        }
    }

    private var statusColor: Color {
        switch invoice.status {
        case .overdue1to7: return .orange
        case .overdue8to30: return .orange
        case .overdue30plus: return .red
        default: return .gray
        }
    }
}

struct PendingReminderRow: View {
    let reminder: ReminderSchedule
    let invoice: Invoice
    let client: Client
    let onSend: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(invoice.invoiceNumber)
                        .font(.headline)

                    Spacer()

                    Text(reminder.escalationLevel.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(reminder.escalationLevel.color)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }

                Text("To: \(client.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(invoice.total.formatted(.currency(code: "USD")))
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            HStack(spacing: 8) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.gray)
                }

                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    DashboardView()
        .modelContainer(AppContainer.shared.container)
}
