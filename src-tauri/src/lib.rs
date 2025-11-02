
use tauri::tray::TrayIconBuilder;
//use tauri::image::Image;
use tokio::time::Duration;

// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![greet])
        .setup(|app| {

            //little tray icon:
            let icon_bytes = include_bytes!("../icons/lemon.png");
            let icon_image = image::load_from_memory(icon_bytes)
                .expect("Failed to load icon")
                .to_rgba8();
            let (width, height) = icon_image.dimensions();
            let icon = tauri::image::Image::new_owned(
                icon_image.into_raw(),
                width,
                height
            );
            
            let tray = TrayIconBuilder::new()
                .icon(icon)
                .build(app)?;

            
            
            //our little timed loop:
            tauri::async_runtime::spawn(async {
                let mut interval = tokio::time::interval(Duration::from_secs(30));
                loop {
                    interval.tick().await;
                    // poll your server here
                    // let response = reqwest::get("http://localhost:3000").await;
                    // let text = response.text().await;
                    match reqwest::get("http://localhost:3000").await {
                        Ok(resp) => match resp.text().await {
                            Ok(text) => println!("Got: {}", text),
                            Err(e) => println!("Error getting text: {}", e),
                        },
                        Err(e) => println!("Error making request: {}", e),
                    }
                    //println!("Got: {}", text);
                }
            });
            Ok(())

        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
