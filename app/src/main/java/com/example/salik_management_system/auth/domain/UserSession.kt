package com.example.salik_management_system.auth.domain

data class UserSession(
    val uid: String,
    val name: String,
    val email: String,
    val role: UserRole,
    val gender: String,
    val avatar: String? = null,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "name" to name,
        "email" to email,
        "role" to role.toFirestore(),
        "gender" to gender,
        "avatar" to avatar,
    )

    companion object {
        fun fromMap(uid: String, map: Map<String, Any?>): UserSession {
            return UserSession(
                uid = uid,
                name = map["name"] as? String ?: "",
                email = map["email"] as? String ?: "",
                role = UserRole.fromString(map["role"] as? String ?: "editor"),
                gender = normalizeGender(map["gender"] as? String),
                avatar = map["avatar"] as? String,
            )
        }

        /** Firestore + salik rules expect `Male` or `Female`. */
        fun normalizeGender(value: String?): String {
            val lower = (value ?: "Male").trim().lowercase()
            return if (lower == "female") "Female" else "Male"
        }
    }
}
