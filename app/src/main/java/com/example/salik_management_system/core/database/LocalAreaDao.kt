package com.example.salik_management_system.core.database

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface LocalAreaDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(area: LocalAreaEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(areas: List<LocalAreaEntity>)

    @Query("SELECT * FROM local_areas ORDER BY area_name ASC")
    suspend fun getAll(): List<LocalAreaEntity>

    @Query("SELECT * FROM local_areas ORDER BY area_name ASC")
    fun watchAll(): Flow<List<LocalAreaEntity>>

    @Query("SELECT * FROM local_areas WHERE area_id = :id LIMIT 1")
    suspend fun getById(id: String): LocalAreaEntity?

    @Query("SELECT * FROM local_areas WHERE bazam_id = :bazamId ORDER BY area_name ASC")
    suspend fun getByBazamId(bazamId: String): List<LocalAreaEntity>

    @Query("SELECT * FROM local_areas WHERE bazam_id = :bazamId ORDER BY area_name ASC")
    fun watchByBazamId(bazamId: String): Flow<List<LocalAreaEntity>>

    @Query("DELETE FROM local_areas WHERE area_id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM local_areas")
    suspend fun deleteAll()
}
