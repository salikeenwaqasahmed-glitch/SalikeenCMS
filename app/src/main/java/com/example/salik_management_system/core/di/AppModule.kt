package com.example.salik_management_system.core.di

import android.content.Context
import android.content.SharedPreferences
import com.example.salik_management_system.core.config.AppConfig
import com.example.salik_management_system.core.crypto.FieldCrypto
import com.example.salik_management_system.core.network.ConnectivityService
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    private const val PREFS_NAME = "salik_prefs"

    @Provides
    @Singleton
    fun provideSharedPreferences(
        @ApplicationContext context: Context,
    ): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    @Provides
    @Singleton
    fun provideFirebaseAuth(): FirebaseAuth = FirebaseAuth.getInstance()

    @Provides
    @Singleton
    fun provideFirebaseFirestore(): FirebaseFirestore = FirebaseFirestore.getInstance()

    @Provides
    @Singleton
    fun provideConnectivityService(
        @ApplicationContext context: Context,
    ): ConnectivityService = ConnectivityService(context)

    @Provides
    @Singleton
    fun provideFieldCrypto(): FieldCrypto {
        return FieldCrypto.fromBase64Key(AppConfig.fieldCryptoKeyBase64)
    }
}
