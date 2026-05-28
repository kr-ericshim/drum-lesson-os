import Foundation
import Supabase

enum SupabaseClientFactory {
    static func makeClient(environment: SupabaseEnvironment) -> SupabaseClient {
        SupabaseClient(supabaseURL: environment.url, supabaseKey: environment.publishableKey)
    }
}
