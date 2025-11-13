//
//  ContentView.swift
//  notif-server-app
//
//  Created by Diego Wahl on 11/12/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var notificationManager: NotificationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if notificationManager.notifications.isEmpty {
                Text("No notifications")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(notificationManager.notifications.sorted(by: { $0.id > $1.id })) { notification in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notification.title)
                                    .font(.headline)
                                Text(notification.message)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Text(notification.timestamp)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))

                            Divider()
                        }
                    }
                }
            }
        }
        .frame(width: 300, height: 400)
    }
}

#Preview {
    ContentView(notificationManager: NotificationManager())
}
