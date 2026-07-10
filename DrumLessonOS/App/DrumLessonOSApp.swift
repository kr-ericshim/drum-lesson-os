import SwiftUI

@main
struct DrumLessonOSApp: App {
    @State private var environment = AppEnvironment.liveOrPreview()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .frame(minWidth: 430, idealWidth: 1_320, minHeight: 560)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1_360, height: 840)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("레슨 추가…") {
                    environment.route = .dashboard
                    environment.dashboard.presentScheduleSheet()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("새로고침") {
                    Task { await environment.refresh() }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }

        Settings {
            SettingsView(
                syncStatus: environment.syncStatus,
                calendar: environment.calendar,
                preferences: environment.preferences,
                localDataDirectoryURL: environment.localDataDirectoryURL
            )
                .frame(minWidth: 640, idealWidth: 900, minHeight: 560)
                .preferredColorScheme(environment.preferences.appearance.colorScheme)
        }
    }
}
