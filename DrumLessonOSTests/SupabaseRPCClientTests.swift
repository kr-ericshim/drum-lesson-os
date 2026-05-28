import Testing
@testable import DrumLessonOS

@MainActor
@Test func rejectsRawRPCOutsideNativeBoundary() {
    let client = SupabaseRPCClient()

    #expect(throws: RepositoryError.self) {
        try client.makeRequest(name: "unsafe_admin_write", payload: [:])
    }
}

@MainActor
@Test func allowsNativeRPCWrapperNames() throws {
    let client = SupabaseRPCClient()
    let request = try client.makeRequest(name: "native_create_student", payload: ["name": "김민지"])

    #expect(request.name == "native_create_student")
}
