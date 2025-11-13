//
//  notif_server_appApp.swift
//  notif-server-app
//
//  Created by Diego Wahl on 11/12/25.
//

import SwiftUI
import UserNotifications

@main
struct notif_server_appApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}



class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var notificationManager = NotificationManager()
    var eventMonitor: EventMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        requestNotificationPermissions()

        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let image = NSImage(named: "lemon") {
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            }
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Create the popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.animates = false
        popover?.delegate = self
        popover?.contentViewController = NSHostingController(rootView: ContentView(notificationManager: notificationManager))

        // Start polling for notifications
        notificationManager.startPolling()

        // Setup event monitor to close popover on click away
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover?.isShown == true {
                strongSelf.popover?.performClose(nil)
            }
        }
    }

    func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            } else {
                print("Notification permission denied")
            }
        }
    }

    @objc func togglePopover(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showMenu()
        } else {
            // Left click - toggle popover
            if popover?.isShown == true {
                closePopover()
            } else {
                showPopover(sender)
            }
        }
    }

    func showPopover(_ sender: NSStatusBarButton) {
        popover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
        eventMonitor?.start()
    }

    func closePopover() {
        popover?.performClose(nil)
        eventMonitor?.stop()
    }

    func showMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Reset Last Seen ID", action: #selector(resetLastSeenId), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc func resetLastSeenId() {
        notificationManager.resetLastSeenId()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
