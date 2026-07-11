import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment

        NavigationSplitView {
            SidebarView(route: $environment.route)
        } detail: {
            RouteContent(route: environment.route)
        }
        .tint(AppTheme.Accent.teaching)
        .preferredColorScheme(environment.preferences.appearance.colorScheme)
        .task {
            await environment.runLaunchMaintenance()
        }
    }
}

enum SidebarDestination: Hashable {
    case dashboard
    case calendar
    case tuition

    var route: AppRoute {
        switch self {
        case .dashboard: .dashboard
        case .calendar: .calendar
        case .tuition: .tuition
        }
    }
}

extension AppRoute {
    var sidebarDestination: SidebarDestination {
        switch self {
        case .calendar: .calendar
        case .tuition: .tuition
        case .dashboard, .student, .lesson: .dashboard
        }
    }
}

private struct SidebarView: View {
    @Binding var route: AppRoute

    var body: some View {
        List(selection: sidebarSelection) {
            Label("대시보드", systemImage: "rectangle.grid.2x2")
                .tag(SidebarDestination.dashboard)
            Label("캘린더", systemImage: "calendar")
                .tag(SidebarDestination.calendar)
            Label("수강비", systemImage: "banknote")
                .tag(SidebarDestination.tuition)
            SettingsLink {
                Label("설정", systemImage: "gearshape")
            }
        }
        .navigationTitle("드럼 레슨 OS")
        .accessibilityLabel("주요 내비게이션")
    }

    private var sidebarSelection: Binding<SidebarDestination> {
        Binding(
            get: { route.sidebarDestination },
            set: { route = $0.route }
        )
    }
}

private struct RouteContent: View {
    @Environment(AppEnvironment.self) private var environment
    let route: AppRoute

    var body: some View {
        switch route {
        case .dashboard:
            DashboardView(viewModel: environment.dashboard)
        case .calendar:
            CalendarView(viewModel: environment.dashboard)
        case .tuition:
            TuitionView(viewModel: environment.tuition)
        case .student(let id):
            StudentDetailRoute(studentId: id, lessonContext: nil)
        case .lesson(let event):
            StudentDetailRoute(studentId: event.studentId, lessonContext: event)
        }
    }
}

private struct StudentDetailRoute: View {
    @Environment(AppEnvironment.self) private var environment
    let studentId: UUID
    let lessonContext: CalendarLessonEvent?

    var body: some View {
        StudentDetailView(
            viewModel: StudentDetailViewModel(
                studentId: studentId,
                lessonContext: lessonContext,
                repository: environment.students,
                writes: environment.writes,
                lessonDrafts: environment.lessonDrafts
            ),
            onStudentDeleted: {
                await environment.refresh()
                environment.route = .dashboard
            }
        )
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    environment.route = .dashboard
                } label: {
                    Label("대시보드", systemImage: "chevron.backward")
                }
                .keyboardShortcut("[", modifiers: .command)
                .help("대시보드로 돌아가기 (⌘[)")
            }
        }
    }
}
