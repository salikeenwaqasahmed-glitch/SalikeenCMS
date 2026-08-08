package com.example.salik_management_system.core.database

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface SyncQueueDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(item: SyncQueueEntity): Long

    @Insert
    suspend fun enqueue(item: SyncQueueEntity): Long

    @Query("SELECT * FROM sync_queue ORDER BY id ASC")
    suspend fun getAll(): List<SyncQueueEntity>

    @Query("SELECT * FROM sync_queue ORDER BY id ASC")
    fun watchAll(): Flow<List<SyncQueueEntity>>

    @Query("SELECT * FROM sync_queue ORDER BY id ASC")
    suspend fun pendingItems(): List<SyncQueueEntity>

    @Query("SELECT COUNT(*) FROM sync_queue")
    suspend fun pendingCount(): Int

    @Query("SELECT COUNT(*) FROM sync_queue")
    fun watchPendingCount(): Flow<Int>

    @Query("SELECT * FROM sync_queue WHERE id = :id LIMIT 1")
    suspend fun getById(id: Long): SyncQueueEntity?

    @Query("DELETE FROM sync_queue WHERE id = :id")
    suspend fun deleteById(id: Long)

    @Query("DELETE FROM sync_queue WHERE collection = :collection AND doc_id = :docId")
    suspend fun deleteForDoc(collection: String, docId: String)

    @Query(
        """
        UPDATE sync_queue
        SET retry_count = :retryCount, last_error = :error
        WHERE id = :id
        """,
    )
    suspend fun updateError(id: Long, error: String, retryCount: Int)

    @Query("DELETE FROM sync_queue")
    suspend fun deleteAll()
}
