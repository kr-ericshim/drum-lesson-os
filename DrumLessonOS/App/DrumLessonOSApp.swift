import SwiftUI

@main
struct DrumLessonOSApp: App {
    @State private var startup = AppStartupState.load()

    var body: some Scene {
        WindowGroup {
            appContent
                .frame(minWidth: 430, idealWidth: 1_320, minHeight: 560)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1_360, height: 840)
        .commands {
            CommandGroup(replacing: .newItem) {
                if case .ready(let environment) = startup {
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
        }

        Settings {
            settingsContent
                .frame(minWidth: 640, idealWidth: 900, minHeight: 560)
        }
    }

    @ViewBuilder
    private var appContent: some View {
        switch startup {
        case .ready(let environment):
            RootView()
                .environment(environment)
                .preferredColorScheme(environment.preferences.appearance.colorScheme)
        case .failed(let failure):
            AppStartupFailureView(failure: failure, retry: reloadEnvironment)
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        switch startup {
        case .ready(let environment):
            SettingsView(
                syncStatus: environment.syncStatus,
                calendar: environment.calendar,
                preferences: environment.preferences,
                localDataDirectoryURL: environment.localDataDirectoryURL,
                localDataBackup: environment.localDataBackup,
                localDataReset: environment.localDataReset,
                onDataChanged: {
                    environment.route = .dashboard
                    await environment.refresh()
                }
            )
            .preferredColorScheme(environment.preferences.appearance.colorScheme)
        case .failed(let failure):
            AppStartupFailureView(failure: failure, retry: reloadEnvironment)
        }
    }

    private func reloadEnvironment() {
        startup = AppStartupState.load()
    }
}
