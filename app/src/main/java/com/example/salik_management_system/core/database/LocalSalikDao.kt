package com.example.salik_management_system.core.database

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface LocalSalikDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(salik: LocalSalikEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(saliks: List<LocalSalikEntity>)

    @Query(
        """
        SELECT * FROM local_saliks
        WHERE sync_status != '${SyncStatus.pendingDelete}'
        AND (:genderFilter IS NULL OR gender_id = :genderFilter)
        AND (:approvalStatus IS NULL OR approval_status = :approvalStatus)
        AND (:addedByUid IS NULL OR :addedByUid = '' OR added_by_uid = :addedByUid)
        """,
    )
    suspend fun getAll(
        genderFilter: String? = null,
        approvalStatus: String? = null,
        addedByUid: String? = null,
    ): List<LocalSalikEntity>

    @Query(
        """
        SELECT * FROM local_saliks
        WHERE sync_status != '${SyncStatus.pendingDelete}'
        AND (:genderFilter IS NULL OR gender_id = :genderFilter)
        AND (:approvalStatus IS NULL OR approval_status = :approvalStatus)
        AND (:addedByUid IS NULL OR :addedByUid = '' OR added_by_uid = :addedByUid)
        """,
    )
    fun watchAll(
        genderFilter: String? = null,
        approvalStatus: String? = null,
        addedByUid: String? = null,
    ): Flow<List<LocalSalikEntity>>

    @Query("SELECT * FROM local_saliks WHERE salik_id = :id LIMIT 1")
    suspend fun getById(id: String): LocalSalikEntity?

    @Query("SELECT * FROM local_saliks WHERE salik_id = :id LIMIT 1")
    fun watchById(id: String): Flow<LocalSalikEntity?>

    @Query(
        """
        SELECT COUNT(*) FROM local_saliks
        WHERE sync_status != '${SyncStatus.pendingDelete}'
        AND (:genderFilter IS NULL OR gender_id = :genderFilter)
        AND (:approvalStatus IS NULL OR approval_status = :approvalStatus)
        AND (:addedByUid IS NULL OR :addedByUid = '' OR added_by_uid = :addedByUid)
        """,
    )
    suspend fun count(
        genderFilter: String? = null,
        approvalStatus: String? = null,
        addedByUid: String? = null,
    ): Int

    @Query("DELETE FROM local_saliks WHERE salik_id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM local_saliks")
    suspend fun deleteAll()

    @Query(
        """
        SELECT local_saliks.* FROM local_saliks
        JOIN saliks_fts ON local_saliks.rowid = saliks_fts.rowid
        WHERE saliks_fts MATCH :query
        AND local_saliks.sync_status != '${SyncStatus.pendingDelete}'
        """,
    )
    suspend fun search(query: String): List<LocalSalikEntity>
}
