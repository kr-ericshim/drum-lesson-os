import SwiftUI

@main
struct DrumLessonOSApp: App {
    @State private var environment = AppEnvironment.liveOrPreview()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .frame(minWidth: 430, idealWidth: 1100, minHeight: 680)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Add Lesson") {
                    environment.dashboard.presentScheduleSheet()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Refresh") {
                    Task { await environment.refresh() }
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
