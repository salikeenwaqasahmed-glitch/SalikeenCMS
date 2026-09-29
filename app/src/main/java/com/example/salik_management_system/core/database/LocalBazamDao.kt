package com.example.salik_management_system.core.database

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface LocalBazamDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(bazam: LocalBazamEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(bazams: List<LocalBazamEntity>)

    @Query("SELECT * FROM local_bazams ORDER BY bazam_name ASC")
    suspend fun getAll(): List<LocalBazamEntity>

    @Query("SELECT * FROM local_bazams ORDER BY bazam_name ASC")
    fun watchAll(): Flow<List<LocalBazamEntity>>

    @Query("SELECT * FROM local_bazams WHERE bazam_id = :id LIMIT 1")
    suspend fun getById(id: String): LocalBazamEntity?

    @Query("DELETE FROM local_bazams WHERE bazam_id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM local_bazams")
    suspend fun deleteAll()
}
