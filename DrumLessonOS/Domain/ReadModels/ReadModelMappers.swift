import Foundation

enum StudentRosterMapper {
    static func map(
        students: [Student],
        progressItems: [ProgressItem],
        assignments: [Assignment],
        nextPlans: [NextLessonPlan],
        notes: [LessonNote],
        todayDate: String
    ) -> [StudentRosterItem] {
        students
            .filter(\.active)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { student in
                mapStudent(
                    student,
                    progressItems: progressItems.filter { $0.studentId == student.id },
                    assignments: assignments.filter { $0.studentId == student.id },
                    nextPlans: nextPlans.filter { $0.studentId == student.id },
                    notes: notes.filter { $0.studentId == student.id },
                    todayDate: todayDate
                )
            }
    }

    static func mapStudent(
        _ student: Student,
        progressItems: [ProgressItem],
        assignments: [Assignment],
        nextPlans: [NextLessonPlan],
        notes: [LessonNote],
        todayDate: String
    ) -> StudentRosterItem {
        let currentFocus = pickCurrentFocus(progressItems: progressItems).map(mapFocus)
        let latestAssignment = pickLatestAssignment(assignments)
        let currentPlan = pickCurrentNextPlan(nextPlans).map(mapNextPlan)
        let latestNote = pickLatestLessonNote(notes)

        return StudentRosterItem(
            id: student.id,
            name: student.name,
            profileCue: student.profileCue,
            primaryWeakPoint: student.primaryWeakPoint,
            active: student.active,
            currentFocus: currentFocus,
            assignmentStatus: latestAssignment?.status,
            nextPlan: currentPlan,
            lastLessonDate: latestNote?.lessonDate,
            attentionFlags: buildAttentionFlags(
                currentFocus: currentFocus,
                assignment: latestAssignment,
                latestNote: latestNote,
                nextPlan: currentPlan,
                todayDate: todayDate
            )
        )
    }

    static func pickCurrentFocus(progressItems: [ProgressItem]) -> ProgressItem? {
        let focused = progressItems
            .filter(\.currentFocus)
            .sorted { ($0.updatedAt ?? $0.observedOn) > ($1.updatedAt ?? $1.observedOn) }
            .first

        return focused
    }

    static func pickLatestAssignment(_ assignments: [Assignment]) -> Assignment? {
        assignments.sorted { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") }.first
    }

    static func pickCurrentNextPlan(_ plans: [NextLessonPlan]) -> NextLessonPlan? {
        plans.sorted { ($0.updatedAt ?? $0.createdAt ?? "") > ($1.updatedAt ?? $1.createdAt ?? "") }.first
    }

    static func pickLatestLessonNote(_ notes: [LessonNote]) -> LessonNote? {
        notes.sorted {
            if $0.lessonDate == $1.lessonDate {
                return ($0.createdAt ?? "") > ($1.createdAt ?? "")
            }
            return $0.lessonDate > $1.lessonDate
        }.first
    }

    static func mapFocus(_ item: ProgressItem) -> ProgressFocusSummary {
        ProgressFocusSummary(
            id: item.id,
            title: item.title,
            category: item.category,
            status: item.status,
            observedOn: item.observedOn,
            detail: item.detail,
            tempoNote: item.tempoNote
        )
    }

    static func mapNextPlan(_ plan: NextLessonPlan) -> StudentNextPlan {
        StudentNextPlan(
            id: plan.id,
            plannedFor: plan.plannedFor,
            priority: plan.priority,
            nextAction: plan.nextAction,
            detail: plan.detail
        )
    }

    private static func buildAttentionFlags(
        currentFocus: ProgressFocusSummary?,
        assignment: Assignment?,
        latestNote: LessonNote?,
        nextPlan: StudentNextPlan?,
        todayDate: String
    ) -> [LessonAttentionFlag] {
        var flags: [LessonAttentionFlag] = []

        if currentFocus == nil {
            flags.append(LessonAttentionFlag(kind: .noCurrentFocus, label: "초점 없음"))
        }

        if assignment?.status == .needsReview {
            flags.append(LessonAttentionFlag(kind: .needsAssignmentReview, label: "과제 확인"))
        }

        if let lessonDate = latestNote?.lessonDate, DateOnly.days(from: lessonDate, to: todayDate) >= 14 {
            flags.append(LessonAttentionFlag(kind: .staleLesson, label: "노트 오래됨"))
        }

        if let plannedFor = nextPlan?.plannedFor, plannedFor <= todayDate {
            flags.append(LessonAttentionFlag(kind: .upcomingPlan, label: "계획 확인"))
        }

        return flags
    }
}

enum StudentDetailMapper {
    static func map(
        student: Student,
        progressItems: [ProgressItem],
        traits: [StudentTrait],
        assignments: [Assignment],
        notes: [LessonNote],
        nextPlans: [NextLessonPlan],
        todayDate: String
    ) -> StudentDetail {
        let roster = StudentRosterMapper.mapStudent(
            student,
            progressItems: progressItems,
            assignments: assignments,
            nextPlans: nextPlans,
            notes: notes,
            todayDate: todayDate
        )

        let mappedProgress = progressItems
            .sorted { $0.observedOn > $1.observedOn }
            .map {
                StudentProgressItem(
                    id: $0.id,
                    category: $0.category,
                    status: $0.status,
                    title: $0.title,
                    currentFocus: $0.currentFocus,
                    observedOn: $0.observedOn,
                    detail: $0.detail,
                    tempoNote: $0.tempoNote
                )
            }

        let recentNotes = notes
            .sorted { $0.lessonDate > $1.lessonDate }
            .map {
                StudentLessonNote(
                    id: $0.id,
                    lessonDate: $0.lessonDate,
                    coveredMaterial: $0.coveredMaterial,
                    observations: $0.observations,
                    practiceAssigned: $0.practiceAssigned,
                    nextStepHint: $0.nextStepHint
                )
            }

        let assignment = StudentRosterMapper.pickLatestAssignment(assignments).map {
            StudentAssignment(id: $0.id, title: $0.title, status: $0.status, dueDate: $0.dueDate, detail: $0.detail)
        }
        let nextPlan = StudentRosterMapper.pickCurrentNextPlan(nextPlans).map(StudentRosterMapper.mapNextPlan)
        let brief = LessonBriefBuilder.build(
            primaryWeakPoint: student.primaryWeakPoint,
            traits: traits,
            currentFocus: roster.currentFocus,
            assignment: assignment,
            recentNotes: recentNotes,
            nextPlan: nextPlan
        )

        return StudentDetail(
            id: student.id,
            name: student.name,
            profileCue: student.profileCue,
            primaryWeakPoint: student.primaryWeakPoint,
            active: student.active,
            currentFocus: roster.currentFocus,
            progressItems: mappedProgress,
            traits: traits.sorted { $0.type.rawValue < $1.type.rawValue },
            assignment: assignment,
            recentNotes: recentNotes,
            nextPlan: nextPlan,
            lessonBrief: brief
        )
    }
}

enum LessonBriefBuilder {
    static func build(
        primaryWeakPoint: String,
        traits: [StudentTrait],
        currentFocus: ProgressFocusSummary?,
        assignment: StudentAssignment?,
        recentNotes: [StudentLessonNote],
        nextPlan: StudentNextPlan?
    ) -> LessonBrief {
        let weakPoint = traits.first { $0.type == .weakPoint }?.detail ?? primaryWeakPoint
        let firstCheck = nextPlan?.nextAction ?? currentFocus?.title ?? weakPoint
        let assignmentCue = assignment.map { "\($0.title) · \($0.status.label)" }

        return LessonBrief(
            firstCheck: firstCheck,
            weakPointBrief: weakPoint,
            assignmentCue: assignmentCue,
            recentObservation: recentNotes.first?.observations
        )
    }
}

enum LessonCloseoutDraftBuilder {
    static func build(
        coveredMaterial: String,
        observations: String,
        practiceAssigned: String,
        selectedChecklistLabels: [String],
        nextStepHint: String,
        fallbackFirstCheck: String
    ) -> LessonCloseoutDraft {
        let checklistSummary = selectedChecklistLabels.joined(separator: "; ")
        let resolvedNextHint = nextStepHint.isEmpty ? fallbackFirstCheck : nextStepHint

        return LessonCloseoutDraft(
            coveredMaterial: coveredMaterial,
            observations: [observations, checklistSummary].filter { !$0.isEmpty }.joined(separator: "\n"),
            practiceAssigned: practiceAssigned,
            nextStepHint: resolvedNextHint,
            nextAction: resolvedNextHint
        )
    }
}

enum CalendarWorkbenchMapper {
    static func map(
        occurrences: [LessonOccurrence],
        students: [StudentRosterItem],
        weekContaining date: Date,
        timezone: String,
        today referenceDate: Date = Date()
    ) -> CalendarWorkbench {
        let calendar = Calendar.iso8601SeoulCompatible
        let resolvedTimeZone = TimeZone(identifier: timezone) ?? .current
        let today = DateOnly.string(from: referenceDate, timeZone: resolvedTimeZone)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let studentsById = Dictionary(uniqueKeysWithValues: students.map { ($0.id, $0) })
        let events = occurrences.filter { $0.status == .scheduled }.compactMap { occurrence -> CalendarLessonEvent? in
            guard let student = studentsById[occurrence.studentId] else { return nil }
            let dateKey = DateOnly.string(fromISOInstant: occurrence.startsAt, timeZoneIdentifier: occurrence.timezone)
            return CalendarLessonEvent(
                id: occurrence.id,
                studentId: occurrence.studentId,
                studentName: student.name,
                title: occurrence.title,
                dateKey: dateKey,
                timeLabel: DateOnly.timeLabel(fromISOInstant: occurrence.startsAt, timeZoneIdentifier: occurrence.timezone),
                durationMinutes: DateOnly.minutes(from: occurrence.startsAt, to: occurrence.endsAt),
                startsAt: occurrence.startsAt,
                endsAt: occurrence.endsAt,
                timezone: occurrence.timezone,
                status: occurrence.status,
                syncStatus: occurrence.nativeCalendarSyncStatus,
                syncError: occurrence.nativeCalendarSyncError,
                firstCheck: student.nextPlan?.nextAction ?? student.currentFocus?.title ?? student.primaryWeakPoint,
                watchFlags: student.attentionFlags
            )
        }

        let days = (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            let dateKey = DateOnly.string(from: day, timeZone: resolvedTimeZone)
            return CalendarDay(
                dateKey: dateKey,
                label: DateOnly.weekdayLabel(from: day),
                isToday: dateKey == today,
                events: events.filter { $0.dateKey == dateKey }.sorted { $0.startsAt < $1.startsAt }
            )
        }
        let weekEvents = days.flatMap(\.events).sorted { $0.startsAt < $1.startsAt }
        let todayEvents = weekEvents.filter { $0.dateKey == today }

        return CalendarWorkbench(
            weekTitle: DateOnly.weekTitle(from: weekStart, to: weekEnd, timeZone: resolvedTimeZone),
            todayDateKey: today,
            days: days,
            todayEvents: todayEvents,
            roster: students,
            selectedEvent: todayEvents.first ?? weekEvents.first
        )
    }
}

enum DateOnly {
    static func today(in timeZone: TimeZone) -> String {
        string(from: Date(), timeZone: timeZone)
    }

    static func weekTitle(from start: Date, to end: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar.iso8601SeoulCompatible
        calendar.timeZone = timeZone
        let startParts = calendar.dateComponents([.year, .month, .day], from: start)
        let endParts = calendar.dateComponents([.year, .month, .day], from: end)
        let startYear = startParts.year ?? 0
        let startMonth = startParts.month ?? 0
        let startDay = startParts.day ?? 0
        let endYear = endParts.year ?? startYear
        let endMonth = endParts.month ?? startMonth
        let endDay = endParts.day ?? startDay

        if startYear != endYear {
            return "\(startYear)년 \(startMonth)월 \(startDay)일 – \(endYear)년 \(endMonth)월 \(endDay)일"
        }
        if startMonth != endMonth {
            return "\(startYear)년 \(startMonth)월 \(startDay)일 – \(endMonth)월 \(endDay)일"
        }
        return "\(startYear)년 \(startMonth)월 \(startDay)–\(endDay)일"
    }

    static func string(from date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .iso8601SeoulCompatible
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func string(fromISOInstant value: String, timeZoneIdentifier: String) -> String {
        guard let date = ISO8601DateFormatter.withFractions.date(from: value) ?? ISO8601DateFormatter.plain.date(from: value) else {
            return String(value.prefix(10))
        }
        return string(from: date, timeZone: TimeZone(identifier: timeZoneIdentifier) ?? .current)
    }

    static func timeLabel(fromISOInstant value: String, timeZoneIdentifier: String) -> String {
        guard let date = ISO8601DateFormatter.withFractions.date(from: value) ?? ISO8601DateFormatter.plain.date(from: value) else {
            return "--:--"
        }
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    static func minutes(from start: String, to end: String) -> Int {
        let startDate = ISO8601DateFormatter.withFractions.date(from: start) ?? ISO8601DateFormatter.plain.date(from: start)
        let endDate = ISO8601DateFormatter.withFractions.date(from: end) ?? ISO8601DateFormatter.plain.date(from: end)
        guard let startDate, let endDate else { return 0 }
        return max(0, Int(endDate.timeIntervalSince(startDate) / 60))
    }

    static func days(from start: String, to end: String) -> Int {
        let formatter = DateFormatter()
        formatter.calendar = .iso8601SeoulCompatible
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        guard let startDate = formatter.date(from: start), let endDate = formatter.date(from: end) else {
            return 0
        }
        return Calendar.iso8601SeoulCompatible.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    static func weekdayLabel(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "EEE d"
        return formatter.string(from: date)
    }
}

extension Calendar {
    static var iso8601SeoulCompatible: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2
        calendar.timeZone = .current
        return calendar
    }
}

extension ISO8601DateFormatter {
    static var withFractions: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    static var plain: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}
