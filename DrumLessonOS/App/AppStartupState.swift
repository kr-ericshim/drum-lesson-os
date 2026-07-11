import AppKit
import SwiftUI

enum AppStartupState {
    case ready(AppEnvironment)
    case failed(AppStartupFailure)

    @MainActor
    static func load(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundle: Bundle? = .main
    ) -> AppStartupState {
        do {
            return .ready(try AppEnvironment.liveOrPreview(environment: environment, bundle: bundle))
        } catch {
            return .failed(AppStartupFailure(
                message: error.localizedDescription,
                dataDirectoryURL: defaultDataDirectoryURL
            ))
        }
    }

    private static var defaultDataDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/DrumLessonOS", isDirectory: true)
    }
}

struct AppStartupFailure {
    var message: String
    var dataDirectoryURL: URL
}

struct AppStartupFailureView: View {
    let failure: AppStartupFailure
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("로컬 데이터를 열 수 없습니다", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(failure.message)
                Text("데이터 폴더에서 문제 파일을 확인하거나 백업을 준비한 뒤 다시 시도하세요.")
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        } actions: {
            Button("다시 시도", action: retry)
                .buttonStyle(.borderedProminent)

            if FileManager.default.fileExists(atPath: failure.dataDirectoryURL.path) {
                Button("Finder에서 데이터 폴더 열기") {
                    NSWorkspace.shared.open(failure.dataDirectoryURL)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(AppTheme.Spacing.xxl)
    }
}
