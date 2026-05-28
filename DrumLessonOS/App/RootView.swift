import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment

        Group {
            if environment.auth.isAuthenticated {
                NavigationSplitView {
                    SidebarView(route: $environment.route)
                } detail: {
                    RouteContent(route: environment.route)
                }
            } else {
                LoginView(viewModel: environment.auth)
            }
        }
        .task {
            await environment.auth.restoreSession()
            if environment.auth.isAuthenticated {
                await environment.dashboard.load()
            }
        }
    }
}

private struct SidebarView: View {
    @Binding var route: AppRoute

    var body: some View {
        List(selection: $route) {
            Label("Dashboard", systemImage: "calendar")
                .tag(AppRoute.dashboard)
            Label("Settings", systemImage: "gearshape")
                .tag(AppRoute.settings)
        }
        .navigationTitle("Drum Lesson OS")
        .accessibilityLabel("Main navigation")
    }
}

private struct RouteContent: View {
    @Environment(AppEnvironment.self) private var environment
    let route: AppRoute

    var body: some View {
        switch route {
        case .dashboard:
            DashboardView(viewModel: environment.dashboard)
        case .student(let id):
            StudentDetailRoute(studentId: id, lessonContext: nil)
        case .lesson(let event):
            StudentDetailRoute(studentId: event.studentId, lessonContext: event)
        case .settings:
            SettingsView(syncStatus: environment.syncStatus, calendar: environment.calendar)
        }
    }
}

private struct StudentDetailRoute: View {
    @Environment(AppEnvironment.self) private var environment
    let studentId: UUID
    let lessonContext: CalendarLessonEvent?

    var body: some View {
        StudentDetailView(viewModel: StudentDetailViewModel(
            studentId: studentId,
            lessonContext: lessonContext,
            repository: environment.students,
            writes: environment.writes
        ))
    }
}
