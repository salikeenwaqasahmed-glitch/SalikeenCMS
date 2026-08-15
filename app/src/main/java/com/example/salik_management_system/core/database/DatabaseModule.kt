package com.example.salik_management_system.core.database

import android.content.Context
import androidx.room.Room
import com.example.salik_management_system.core.config.AppConfig
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    @Provides
    @Singleton
    fun provideAppDatabase(
        @ApplicationContext context: Context,
    ): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            AppConfig.roomDbName,
        ).fallbackToDestructiveMigration()
            .build()
    }

    @Provides
    fun provideLocalUserDao(db: AppDatabase): LocalUserDao = db.localUserDao()

    @Provides
    fun provideLocalSalikDao(db: AppDatabase): LocalSalikDao = db.localSalikDao()

    @Provides
    fun provideLocalAreaDao(db: AppDatabase): LocalAreaDao = db.localAreaDao()

    @Provides
    fun provideLocalBazamDao(db: AppDatabase): LocalBazamDao = db.localBazamDao()

    @Provides
    fun provideSyncQueueDao(db: AppDatabase): SyncQueueDao = db.syncQueueDao()

    @Provides
    fun provideLocalAppKvDao(db: AppDatabase): LocalAppKvDao = db.localAppKvDao()
}
