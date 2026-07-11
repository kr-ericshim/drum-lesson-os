# Active Technology Stack

## Runtime

- **Application:** macOS SwiftUI
- **Language:** Swift 6.2
- **Project generation:** XcodeGen with `project.yml` as the source of truth
- **Minimum deployment target:** macOS 15

## Persistence And Integrations

- **Canonical data store:** Local SQLite under Application Support
- **Data access:** Repository protocols backed by `LocalSQLiteRepository`
- **Scheduling composition:** `CalendarBackedScheduleRepository`
- **Apple Calendar boundary:** EventKit
- **Calendar durability:** Atomic local JSON outbox for retryable EventKit work
- **Preferences:** `UserDefaults` through `AppPreferences`
- **Portable backup:** Versioned `.drumlessonbackup` JSON envelope

## Verification

- **Test framework:** Swift Testing under `DrumLessonOSTests/`
- **Main gate:** `npm run verify`
- **Static analysis:** `xcodebuild ... analyze`
- **Release launch check:** `CONFIGURATION=Release ./script/build_and_run.sh --verify`
- **Direct UAT:** Native file panels, accessibility, EventKit permissions, and iCloud propagation

## Why This Stack

The active product serves one instructor on one Mac. Local SQLite provides transactional ownership of teaching records without a hosted account boundary. EventKit connects app-owned schedules to Apple Calendar, while the local outbox keeps failed calendar operations visible and retryable across launches.

## Not Active

Next.js, Tailwind, shadcn/ui, Prisma, Supabase, hosted authentication, and Keychain session restoration belong to superseded implementation stages. Reintroducing hosted or multi-device infrastructure requires an explicit product-scope decision.

## Primary Sources

- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [EventKit](https://developer.apple.com/documentation/eventkit)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
