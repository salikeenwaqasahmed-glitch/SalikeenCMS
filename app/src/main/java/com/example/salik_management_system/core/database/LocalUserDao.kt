package com.example.salik_management_system.core.database

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface LocalUserDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(user: LocalUserEntity)

    @Query("SELECT * FROM local_users")
    suspend fun getAll(): List<LocalUserEntity>

    @Query("SELECT * FROM local_users")
    fun watchAll(): Flow<List<LocalUserEntity>>

    @Query("SELECT * FROM local_users WHERE uid = :uid LIMIT 1")
    suspend fun getByUid(uid: String): LocalUserEntity?

    @Query("SELECT * FROM local_users WHERE lower(email) = lower(:email) LIMIT 1")
    suspend fun getByEmail(email: String): LocalUserEntity?

    @Query("DELETE FROM local_users WHERE uid = :uid")
    suspend fun deleteByUid(uid: String)

    @Query("DELETE FROM local_users")
    suspend fun deleteAll()
}
