package com.example.salik_management_system.core.database

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface LocalAppKvDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(row: LocalAppKvEntity)

    @Query("SELECT * FROM local_app_kv")
    suspend fun getAll(): List<LocalAppKvEntity>

    @Query("SELECT * FROM local_app_kv")
    fun watchAll(): Flow<List<LocalAppKvEntity>>

    @Query("SELECT value FROM local_app_kv WHERE `key` = :key LIMIT 1")
    suspend fun get(key: String): String?

    @Query("DELETE FROM local_app_kv WHERE `key` = :key")
    suspend fun delete(key: String)

    @Query("DELETE FROM local_app_kv")
    suspend fun deleteAll()
}
