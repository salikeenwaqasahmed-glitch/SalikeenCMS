package com.example.salik_management_system.features.saliks.data.repository

import com.example.salik_management_system.core.data.kAreas
import com.example.salik_management_system.core.data.kBazams
import com.example.salik_management_system.core.data.findArea
import com.example.salik_management_system.core.data.findBazam
import com.example.salik_management_system.core.database.LocalAreaDao
import com.example.salik_management_system.core.database.LocalBazamDao
import com.example.salik_management_system.core.database.SyncStatus
import com.example.salik_management_system.core.database.enqueueSync
import com.example.salik_management_system.features.saliks.data.mapper.toDomain
import com.example.salik_management_system.features.saliks.data.mapper.toEntity
import com.example.salik_management_system.features.saliks.domain.model.Area
import com.example.salik_management_system.features.saliks.domain.model.Bazam
import com.example.salik_management_system.features.saliks.domain.model.kDefaultBazamId
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AreaRepository @Inject constructor(
    private val areaDao: LocalAreaDao,
    private val bazamDao: LocalBazamDao,
    private val syncQueueDao: com.example.salik_management_system.core.database.SyncQueueDao,
) {
    fun watchAreas(): Flow<List<Area>> =
        areaDao.watchAll().map { rows ->
            val areas = rows
                .filter {
                    it.syncStatus != SyncStatus.pendingDelete &&
                        it.syncStatus != SyncStatus.alias
                }
                .map { it.toDomain() }
                .sortedBy { it.areaName.lowercase() }
            if (areas.isNotEmpty()) areas else kAreas.sortedBy { it.areaName.lowercase() }
        }

    fun watchBazams(): Flow<List<Bazam>> =
        bazamDao.watchAll().map { rows ->
            val bazams = rows
                .filter { it.syncStatus != SyncStatus.pendingDelete }
                .map { it.toDomain() }
                .sortedBy { it.bazamName.lowercase() }
            if (bazams.isNotEmpty()) bazams else kBazams
        }

    suspend fun resolveBazam(bazamId: String): Bazam? {
        if (bazamId.isEmpty()) return null
        findBazam(bazamId)?.let { return it }
        val row = bazamDao.getById(bazamId) ?: return null
        if (row.syncStatus == SyncStatus.pendingDelete) return null
        return row.toDomain()
    }

    suspend fun resolveArea(areaId: String): Area? {
        if (areaId.isEmpty()) return null
        findArea(areaId)?.let { return it }
        val row = areaDao.getById(areaId) ?: return null
        if (row.syncStatus == SyncStatus.pendingDelete) return null
        return row.toDomain()
    }

    suspend fun areasForBazam(bazamId: String): List<Area> {
        val id = bazamId.trim().ifEmpty { kDefaultBazamId }
        return allAreasLocal()
            .filter { it.bazamId == id }
            .sortedBy { it.areaName.lowercase() }
    }

    suspend fun findAreaByName(name: String): Area? {
        val normalized = name.trim().lowercase()
        if (normalized.isEmpty()) return null
        return allAreasLocal().firstOrNull { it.areaName.trim().lowercase() == normalized }
    }

    suspend fun createArea(name: String, bazamId: String = kDefaultBazamId): Area {
        findAreaByName(name)?.let { return it }
        val id = UUID.randomUUID().toString()
        val area = Area(
            areaId = id,
            areaName = name.trim(),
            bazamId = bazamId.trim().ifEmpty { kDefaultBazamId },
        )
        areaDao.upsert(area.toEntity(SyncStatus.pendingCreate))
        syncQueueDao.enqueueSync("areas", "create", id, area.toMap())
        return area
    }

    suspend fun upsertAreaLocal(area: Area, syncStatus: String = SyncStatus.synced) {
        areaDao.upsert(area.toEntity(syncStatus))
    }

    suspend fun upsertBazamLocal(bazam: Bazam, syncStatus: String = SyncStatus.synced) {
        bazamDao.upsert(bazam.toEntity(syncStatus))
    }

    private suspend fun allAreasLocal(): List<Area> {
        val rows = areaDao.getAll()
        if (rows.isEmpty()) return kAreas
        return rows
            .filter {
                it.syncStatus != SyncStatus.pendingDelete &&
                    it.syncStatus != SyncStatus.alias
            }
            .map { it.toDomain() }
    }
}
