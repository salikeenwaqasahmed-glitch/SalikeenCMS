package com.example.salik_management_system.ui.navigation

object SalikRoutes {
    const val Login = "login"
    const val Dashboard = "dashboard"
    const val Bazams = "bazams/{bazamId}"
    const val Saliks = "saliks"
    const val SalikProfile = "saliks/profile/{id}"
    const val SalikAdd = "saliks/add"
    const val SalikEdit = "saliks/edit/{id}"
    const val SalikPending = "saliks/pending"
    const val SalikDuplicates = "saliks/duplicates"
    const val SalikMessageQueue = "saliks/message-queue"
    const val Settings = "settings"

    fun bazams(bazamId: String) = "bazams/$bazamId"
    fun salikProfile(id: String) = "saliks/profile/$id"
    fun salikEdit(id: String) = "saliks/edit/$id"

    val bottomBarRoutes = setOf(Dashboard, Saliks, Settings)

    fun showsBottomBar(route: String?): Boolean {
        if (route == null) return false
        return route == Dashboard || route == Saliks || route == Settings
    }
}
