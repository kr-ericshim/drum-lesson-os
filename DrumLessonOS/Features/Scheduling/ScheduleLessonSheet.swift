import SwiftUI

struct ScheduleLessonSheet: View {
    @Environment(\.dismiss) private var dismiss
    let repository: ScheduleRepository
    let roster: [StudentRosterItem]
    var onSaved: () async -> Void = {}

    @State private var form: ScheduleLessonFormState
    @State private var errorMessage: String?

    init(repository: ScheduleRepository, roster: [StudentRosterItem], onSaved: @escaping () async -> Void = {}) {
        self.repository = repository
        self.roster = roster
        self.onSaved = onSaved
        _form = State(initialValue: ScheduleLessonFormState(roster: roster))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Add Lesson", subtitle: "Creates Supabase schedule data first, then native calendar sync can run.")

            if roster.isEmpty {
                ContentUnavailableView("No active students", systemImage: "person.crop.circle.badge.exclamationmark")
            } else {
                Form {
                    Picker("Mode", selection: $form.mode) {
                        ForEach(ScheduleLessonMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Student", selection: $form.selectedStudentId) {
                        ForEach(roster) { student in
                            Text(student.name).tag(Optional(student.id))
                        }
                    }

                    TextField("Title", text: $form.title)
                    DatePicker(form.mode == .oneOff ? "Start" : "First lesson", selection: $form.startDate)

                    Stepper(value: $form.durationMinutes, in: 15...240, step: 5) {
                        Text("Duration: \(form.durationMinutes) min")
                    }

                    if form.mode == .weekly {
                        Picker("Weekday", selection: $form.recurrenceWeekday) {
                            ForEach(ScheduleLessonFormState.weekdayOptions, id: \.value) { option in
                                Text(option.label).tag(option.value)
                            }
                        }

                        Stepper(value: $form.recurrenceInterval, in: 1...12) {
                            Text("Every \(form.recurrenceInterval) week\(form.recurrenceInterval == 1 ? "" : "s")")
                        }

                        Toggle("Set end date", isOn: $form.hasEndDate)
                        if form.hasEndDate {
                            DatePicker("Ends on", selection: $form.endDate, displayedComponents: .date)
                        }
                    }

                    TextField("Timezone", text: $form.timezone)
                }
                .formStyle(.grouped)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                Spacer()
                Button {
                    Task { await save() }
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(roster.isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 560, minHeight: 520)
    }

    private func save() async {
        do {
            switch form.mode {
            case .oneOff:
                _ = try await repository.createOneOffOccurrence(form.makeOneOffInput())
            case .weekly:
                _ = try await repository.createWeeklySchedule(form.makeWeeklyInput())
            }
            await onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum ScheduleLessonMode: String, CaseIterable, Identifiable {
    case oneOff
    case weekly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .oneOff: "One-off"
        case .weekly: "Weekly"
        }
    }
}

struct ScheduleLessonFormState: Equatable {
    static let weekdayOptions = [
        (value: 0, label: "Sunday"),
        (value: 1, label: "Monday"),
        (value: 2, label: "Tuesday"),
        (value: 3, label: "Wednesday"),
        (value: 4, label: "Thursday"),
        (value: 5, label: "Friday"),
        (value: 6, label: "Saturday")
    ]

    var roster: [StudentRosterItem]
    var mode: ScheduleLessonMode
    var selectedStudentId: EntityID?
    var title: String
    var startDate: Date
    var durationMinutes: Int
    var timezone: String
    var recurrenceInterval: Int
    var recurrenceWeekday: Int
    var hasEndDate: Bool
    var endDate: Date

    init(roster: [StudentRosterItem], now: Date = Date()) {
        self.roster = roster
        self.mode = .oneOff
        self.selectedStudentId = roster.first(where: \.active)?.id ?? roster.first?.id
        self.title = roster.first(where: \.active).map { "\($0.name) drum lesson" } ?? "Drum lesson"
        self.startDate = now
        self.durationMinutes = 50
        self.timezone = TimeZone.current.identifier
        self.recurrenceInterval = 1
        self.recurrenceWeekday = max(0, Calendar.iso8601SeoulCompatible.component(.weekday, from: now) - 1)
        self.hasEndDate = false
        self.endDate = Calendar.iso8601SeoulCompatible.date(byAdding: .month, value: 2, to: now) ?? now
    }

    func makeOneOffInput() throws -> ScheduleLessonInput {
        guard let selectedStudentId else {
            throw RepositoryError(message: "Choose a student.")
        }

        let endDate = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startDate) ?? startDate
        return ScheduleLessonInput(
            studentId: selectedStudentId,
            title: title,
            startsAt: ISO8601DateFormatter.plain.string(from: startDate),
            endsAt: ISO8601DateFormatter.plain.string(from: endDate),
            timezone: timezone,
            durationMinutes: durationMinutes
        )
    }

    func makeWeeklyInput() throws -> WeeklyScheduleInput {
        guard let selectedStudentId else {
            throw RepositoryError(message: "Choose a student.")
        }

        return WeeklyScheduleInput(
            studentId: selectedStudentId,
            title: title,
            defaultDurationMinutes: durationMinutes,
            timezone: timezone,
            recurrenceInterval: recurrenceInterval,
            recurrenceWeekday: recurrenceWeekday,
            startsOn: DateOnly.string(from: startDate, timeZone: .current),
            endsOn: hasEndDate ? DateOnly.string(from: endDate, timeZone: .current) : nil,
            startTime: Self.timeString(from: startDate)
        )
    }

    private static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .iso8601SeoulCompatible
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct EditOccurrenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    let event: CalendarLessonEvent
    let repository: ScheduleRepository
    var onSaved: () async -> Void = {}

    @State private var form: EditOccurrenceFormState
    @State private var errorMessage: String?

    init(event: CalendarLessonEvent, repository: ScheduleRepository, onSaved: @escaping () async -> Void = {}) {
        self.event = event
        self.repository = repository
        self.onSaved = onSaved
        _form = State(initialValue: EditOccurrenceFormState(event: event))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Edit Occurrence", subtitle: event.studentName)

            Form {
                DatePicker("Start", selection: $form.startDate)
                Stepper(value: $form.durationMinutes, in: 15...240, step: 5) {
                    Text("Duration: \(form.durationMinutes) min")
                }
                TextField("Timezone", text: $form.timezone)
            }
            .formStyle(.grouped)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                Spacer()
                Button {
                    Task { await save() }
                } label: {
                    Label("Save Changes", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 360)
    }

    private func save() async {
        do {
            _ = try await repository.editOccurrence(form.makeInput(occurrenceId: event.id))
            await onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct EditOccurrenceFormState: Equatable {
    var startDate: Date
    var durationMinutes: Int
    var timezone: String

    init(event: CalendarLessonEvent) {
        let start = ISO8601DateFormatter.withFractions.date(from: event.startsAt) ?? ISO8601DateFormatter.plain.date(from: event.startsAt) ?? Date()
        self.startDate = start
        self.durationMinutes = max(15, event.durationMinutes)
        self.timezone = TimeZone.current.identifier
    }

    func makeInput(occurrenceId: EntityID) -> EditOccurrenceInput {
        let endDate = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startDate) ?? startDate
        return EditOccurrenceInput(
            occurrenceId: occurrenceId,
            startsAt: ISO8601DateFormatter.plain.string(from: startDate),
            endsAt: ISO8601DateFormatter.plain.string(from: endDate),
            timezone: timezone
        )
    }
}
