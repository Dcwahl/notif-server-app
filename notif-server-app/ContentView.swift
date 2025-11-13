//
//  ContentView.swift
//  notif-server-app
//
//  Created by Diego Wahl on 11/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .frame(width: 300, height: 400)
        .padding()
    }
}

#Preview {
    ContentView()
}
