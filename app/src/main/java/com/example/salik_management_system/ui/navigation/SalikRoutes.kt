package com.example.salik_management_system.ui.navigation

object SalikRoutes {
    const val Login = "login"
    const val Dashboard = "dashboard"
    const val Bazams = "bazams/{bazamId}"
    const val Saliks = "saliks?areaId={areaId}&bazamId={bazamId}&type={type}"
    const val SalikProfile = "saliks/profile/{id}"

    const val SalikAdd = "saliks/add"
    const val SalikEdit = "saliks/edit/{id}"
    const val SalikPending = "saliks/pending"
    const val SalikDuplicates = "saliks/duplicates"
    const val SalikMessageQueue = "saliks/message-queue"
    const val Settings = "settings"

    fun bazams(bazamId: String) = "bazams/$bazamId"
    fun saliks(areaId: String? = null, bazamId: String? = null, type: String? = null): String {
        val builder = StringBuilder("saliks?")
        if (areaId != null) builder.append("areaId=$areaId&")
        if (bazamId != null) builder.append("bazamId=$bazamId&")
        if (type != null) builder.append("type=$type&")
        return builder.toString().removeSuffix("&").removeSuffix("?")
    }
    fun salikProfile(id: String) = "saliks/profile/$id"

    fun salikEdit(id: String) = "saliks/edit/$id"

    fun showsBottomBar(route: String?): Boolean {
        if (route == null) return false
        return route == Dashboard || route == Saliks || route == Settings
    }
}
