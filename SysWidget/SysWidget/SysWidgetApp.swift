//
//  SysWidgetApp.swift
//  SysWidget
//
//  Created by Noah Zitsman on 3/12/25.
//

import SwiftUI

@main
struct SysWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 700, minHeight: 800)
        }
        #if os(macOS)
        .windowStyle(DefaultWindowStyle())
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        #endif
    }
}
