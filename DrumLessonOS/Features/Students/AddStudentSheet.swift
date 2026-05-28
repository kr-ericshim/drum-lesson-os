import SwiftUI

struct AddStudentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let writes: StudentWriteRepository
    var onCreated: (EntityID) async -> Void = { _ in }

    @State private var form = AddStudentFormState()
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Add Student", subtitle: "Create the profile, then fill teaching context from detail.")

            Form {
                TextField("Name", text: $form.name)
                TextField("Profile cue", text: $form.profileCue, axis: .vertical)
                TextField("Weak point", text: $form.primaryWeakPoint, axis: .vertical)
                Toggle("Active", isOn: $form.active)
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
                    Label("Create Student", systemImage: "person.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 380)
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let input = form.makeInput()
            try StudentEditingValidation.validate(input)
            let id = try await writes.createStudent(input)
            await onCreated(id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AddStudentFormState: Equatable {
    var name = ""
    var profileCue = ""
    var primaryWeakPoint = ""
    var active = true

    func makeInput() -> StudentProfileInput {
        StudentProfileInput(
            studentId: nil,
            name: name,
            profileCue: profileCue,
            primaryWeakPoint: primaryWeakPoint,
            active: active
        )
    }
}
