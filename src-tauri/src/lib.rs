use tauri::Manager;
use tauri::menu::{Menu, MenuItem};
use tauri::tray::TrayIconBuilder;
use tauri_plugin_notification::NotificationExt;
//use tauri::image::Image;
use serde::Deserialize;
use std::sync::Mutex;
use tokio::time::Duration;

//TODO: whole window situation, https://docs.rs/tauri/2.0.0/tauri/window/struct.Window.html

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

// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
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
            //this just means don't show in dock:
            #[cfg(target_os = "macos")]
            app.set_activation_policy(tauri::ActivationPolicy::Accessory);

            //little tray icon:
            let icon_bytes = include_bytes!("../icons/lemon.png");
            let icon_image = image::load_from_memory(icon_bytes)
                .expect("Failed to load icon")
                .to_rgba8();
            let (width, height) = icon_image.dimensions();
            let icon = tauri::image::Image::new_owned(icon_image.into_raw(), width, height);
            //do like a right click menu i guess
            let menu = Menu::new(app)?;
            let quit_item = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
            menu.append(&quit_item)?;

            let tray = TrayIconBuilder::new()
                .icon(icon)
                .menu(&menu)
                .build(app)?;

            let app_handle = app.handle().clone();

            //our little timed loop:
            tauri::async_runtime::spawn(async move {
                let mut interval = tokio::time::interval(Duration::from_secs(30));
                loop {
                    interval.tick().await; //30 sec interval

                    match reqwest::get("http://localhost:3000/notifications").await {
                        Ok(resp) => match resp.text().await {
                            Ok(text) => {
                                // Usa app_handle en vez de app:
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
