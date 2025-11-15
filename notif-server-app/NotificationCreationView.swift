//
//  NotificationCreationView.swift
//  notif-server-app
//
//  Created by Diego Wahl on 11/13/25.
//

import SwiftUI

struct NotificationCreationView: View {
    @State private var title = ""
    @State private var message = ""
    @State private var scheduledTime = Date()
    @State private var isScheduled = false

    var onSubmit: (String, String, Date?) -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Notification")
                .font(.headline)

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)

            TextField("Message", text: $message, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)

            Toggle("Schedule?", isOn: $isScheduled)

            if isScheduled {
                DatePicker("Send at", selection: $scheduledTime, in: Date()...)
                    .datePickerStyle(.field)
                    .controlSize(.large)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    onClose()
                }
                .keyboardShortcut(.cancelAction)

                Button("Send") {
                    onSubmit(title, message, isScheduled ? scheduledTime : nil)
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty || message.isEmpty)
            }
        }
        .padding()
        .frame(width: 450)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 10)
        .onAppear {
            scheduledTime = Date()
        }
    }
}

#Preview {
    NotificationCreationView(
        onSubmit: { title, message, scheduledTime in
            if let time = scheduledTime {
                print("Title: \(title), Message: \(message), Time: \(time)")
            } else {
                print("Title: \(title), Message: \(message), Send immediately")
            }
        },
        onClose: {
            print("Closed")
        }
    )
}
