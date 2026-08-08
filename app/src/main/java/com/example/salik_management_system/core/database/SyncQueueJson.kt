package com.example.salik_management_system.core.database

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

private val syncJson = Json { encodeDefaults = true; ignoreUnknownKeys = true }

fun Map<String, Any?>.toSyncPayloadJson(): String {
    return syncJson.encodeToString(toJsonElement())
}

fun String.decodeSyncPayload(): Map<String, Any?> {
    val element = syncJson.parseToJsonElement(this)
    return (element as? JsonObject)?.toAnyMap().orEmpty()
}

suspend fun SyncQueueDao.enqueueSync(
    collection: String,
    operation: String,
    docId: String,
    payload: Map<String, Any?>,
): Long {
    return enqueue(
        SyncQueueEntity(
            collection = collection,
            operation = operation,
            docId = docId,
            payloadJson = payload.toSyncPayloadJson(),
        ),
    )
}

private fun Map<String, Any?>.toJsonElement(): JsonObject = buildJsonObject {
    for ((key, value) in this@toJsonElement) {
        put(key, value.toJsonElement())
    }
}

@Suppress("UNCHECKED_CAST")
private fun Any?.toJsonElement(): JsonElement = when (this) {
    null -> JsonNull
    is Boolean -> JsonPrimitive(this)
    is Number -> JsonPrimitive(this)
    is String -> JsonPrimitive(this)
    is Map<*, *> -> (this as Map<String, Any?>).toJsonElement()
    is List<*> -> JsonArray(map { it.toJsonElement() })
    else -> JsonPrimitive(toString())
}

private fun JsonObject.toAnyMap(): Map<String, Any?> =
    entries.associate { (k, v) -> k to v.toAny() }

private fun JsonElement.toAny(): Any? = when (this) {
    is JsonNull -> null
    is JsonPrimitive -> when {
        isString -> content
        content.equals("true", true) || content.equals("false", true) -> content.toBoolean()
        content.toLongOrNull() != null -> content.toLong()
        content.toDoubleOrNull() != null -> content.toDouble()
        else -> content
    }
    is JsonObject -> toAnyMap()
    is JsonArray -> map { it.toAny() }
}
