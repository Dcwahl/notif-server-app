//
//  Notification.swift
//  notif-server-app
//
//  Created by Diego Wahl on 11/12/25.
//

import Foundation
import UserNotifications

struct AppNotification: Codable, Identifiable {
    let id: Int64
    let title: String
    let message: String
    let timestamp: String
}

class NotificationManager: ObservableObject {
    @Published var notifications: [AppNotification] = []
    private var timer: Timer?
    private let defaults = UserDefaults.standard
    private let lastSeenIdKey = "lastSeenNotificationId"

    var lastSeenId: Int64 {
        get {
            return defaults.object(forKey: lastSeenIdKey) as? Int64 ?? 0
        }
        set {
            defaults.set(newValue, forKey: lastSeenIdKey)
        }
    }

    func startPolling() {
        // Poll immediately
        fetchNotifications()

        // Then every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.fetchNotifications()
        }
    }

    func fetchNotifications() {
        print("here")
        var urlComponents = URLComponents(string: "http://localhost:3000/notifications")
        urlComponents?.queryItems = [URLQueryItem(name: "id", value: String(lastSeenId))]

        guard let url = urlComponents?.url else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching notifications: \(error?.localizedDescription ?? "unknown")")
                return
            }

            do {
                let decoded = try JSONDecoder().decode([AppNotification].self, from: data)
                DispatchQueue.main.async {
                    // Only process if we have new notifications
                    if !decoded.isEmpty {
                        print("📬 Received \(decoded.count) new notifications")
                        self.notifications.append(contentsOf: decoded)

                        // Show native notifications for each new notification with a small delay
                        for (index, notification) in decoded.enumerated() {
                            print("  → Showing notification: \(notification.title)")
                            // Add delay to prevent macOS from collapsing notifications
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.0) {
                                self.showNativeNotification(notification)
                            }
                        }

                        // Update last seen ID to the highest ID received
                        if let maxId = decoded.map({ $0.id }).max() {
                            self.lastSeenId = maxId
                            print("📝 Updated last_seen_id to: \(maxId)")
                        }
                    } else {
                        print("✅ No new notifications (last_seen_id: \(self.lastSeenId))")
                    }
                }
            } catch {
                print("Error decoding: \(error)")
            }
        }.resume()
    }

    func showNativeNotification(_ notification: AppNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = .default  // Use default sound (change to nil for silent)

        // Use UUID to ensure each notification request is unique
        // This prevents macOS from deduplicating notifications during development
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Show immediately
        )

        print("    🔔 Attempting to add notification request for ID: \(notification.id)")
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("    ❌ Error showing notification \(notification.id): \(error)")
            } else {
                print("    ✅ Successfully added notification \(notification.id)")
            }
        }
    }

    func resetLastSeenId() {
        lastSeenId = 0
        notifications.removeAll()
        print("Last seen ID reset to 0")
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
}
