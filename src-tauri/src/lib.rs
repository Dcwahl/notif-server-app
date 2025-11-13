use tauri::Manager;
use tauri::menu::{Menu, MenuItem};
use tauri::tray::TrayIconBuilder;
use tauri::WebviewWindowBuilder;
use tauri_plugin_notification::NotificationExt;
use serde::Deserialize;
use std::sync::Mutex;
use tokio::time::Duration;

struct AppState {
    last_seen_id: Mutex<u64>,
}

#[derive(Deserialize, Debug)]
struct Notification {
    id: i64,
    title: String,
    message: String,
    timestamp: String,
}

#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_notification::init())
        .on_menu_event(|app, event| {
            if event.id() == "quit" {
                app.exit(0);
            }
        })
        .manage(AppState {
            last_seen_id: Mutex::new(0),
        })
        .invoke_handler(tauri::generate_handler![greet])
        .setup(|app| {
            #[cfg(target_os = "macos")]
            app.set_activation_policy(tauri::ActivationPolicy::Accessory);

            let icon_bytes = include_bytes!("../icons/lemon.png");
            let icon_image = image::load_from_memory(icon_bytes)
                .expect("Failed to load icon")
                .to_rgba8();
            let (width, height) = icon_image.dimensions();
            let icon = tauri::image::Image::new_owned(icon_image.into_raw(), width, height);
            
            let menu = Menu::new(app)?;
            let quit_item = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
            menu.append(&quit_item)?;

            let tray = TrayIconBuilder::new()
                .icon(icon)
                .menu(&menu)
                .on_tray_icon_event(|tray, event| {
                    match event {
                        tauri::tray::TrayIconEvent::Click {
                            button: tauri::tray::MouseButton::Left,
                            ..
                        } => {
                            println!("Tray icon left-clicked!");
                            
                            let app = tray.app_handle();
                            
                            // Try to get existing window first
                            if let Some(window) = app.get_webview_window("notifications") {
                                let _ = window.show();
                                let _ = window.set_focus();
                            } else {
                                // Create new window if it doesn't exist
                                let _ = WebviewWindowBuilder::new(
                                    app, 
                                    "notifications", 
                                    tauri::WebviewUrl::App("/index.html".into())
                                )
                                .title("Notifications")
                                .inner_size(400.0, 600.0)
                                .resizable(true)
                                .build();
                            }
                        }
                        tauri::tray::TrayIconEvent::Click {
                            button: tauri::tray::MouseButton::Right,
                            ..
                        } => {
                            println!("Tray icon right-clicked!");
                        }
                        _ => {}
                    }
                })
                .build(app)?;

            let app_handle = app.handle().clone();

            tauri::async_runtime::spawn(async move {
                let mut interval = tokio::time::interval(Duration::from_secs(30));
                loop {
                    interval.tick().await;

                    match reqwest::get("http://localhost:3000/notifications").await {
                        Ok(resp) => match resp.text().await {
                            Ok(text) => {
                                let notifications: Vec<Notification> =
                                    match serde_json::from_str(&text) {
                                        Ok(n) => n,
                                        Err(e) => {
                                            println!("Error parsing JSON: {}", e);
                                            continue;
                                        }
                                    };

                                for notif in &notifications {
                                    app_handle
                                        .notification()
                                        .builder()
                                        .title(&notif.title)
                                        .body(&notif.message)
                                        .show()
                                        .unwrap();
                                }
                            }
                            Err(e) => println!("Error getting text: {}", e),
                        },
                        Err(e) => println!("Error making request: {}", e),
                    }
                }
            });

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}