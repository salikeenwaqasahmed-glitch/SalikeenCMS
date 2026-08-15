package com.example.salik_management_system.core.database

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [
        LocalUserEntity::class,
        LocalSalikEntity::class,
        LocalAreaEntity::class,
        LocalBazamEntity::class,
        SyncQueueEntity::class,
        LocalAppKvEntity::class,
        SalikFtsEntity::class,
    ],
    version = 1,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun localUserDao(): LocalUserDao
    abstract fun localSalikDao(): LocalSalikDao
    abstract fun localAreaDao(): LocalAreaDao
    abstract fun localBazamDao(): LocalBazamDao
    abstract fun syncQueueDao(): SyncQueueDao
    abstract fun localAppKvDao(): LocalAppKvDao
}
