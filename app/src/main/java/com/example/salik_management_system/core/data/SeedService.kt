package com.example.salik_management_system.core.data

import com.google.firebase.Timestamp
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

/** Seeds reference bazams + areas into Firestore (admin post-login / sync). */
@Singleton
class SeedService @Inject constructor(
    private val firestore: FirebaseFirestore,
) {
    suspend fun seedIfNeeded() {
        seedBazamsIfNeeded()
        seedAreasIfNeeded()
    }

    private suspend fun seedAreasIfNeeded() {
        val flag = firestore.document(SEED_FLAG_DOC).get().await()
        if (flag.exists()) return

        val batch = firestore.batch()
        for (area in kAreas) {
            batch.set(firestore.collection("areas").document(area.areaId), area.toMap())
        }
        batch.set(
            firestore.document(SEED_FLAG_DOC),
            mapOf("seededAt" to Timestamp.now()),
        )
        batch.commit().await()
    }

    /** Always upserts default bazams (merge). Safe for existing installs. */
    private suspend fun seedBazamsIfNeeded() {
        val batch = firestore.batch()
        for (bazam in kBazams) {
            batch.set(
                firestore.collection("bazams").document(bazam.bazamId),
                bazam.toMap(),
                SetOptions.merge(),
            )
        }
        for (area in kAreas) {
            batch.set(
                firestore.collection("areas").document(area.areaId),
                mapOf("bazamId" to area.bazamId),
                SetOptions.merge(),
            )
        }
        batch.set(
            firestore.document(BAZAMS_SEED_FLAG_DOC),
            mapOf("seededAt" to Timestamp.now()),
        )
        batch.commit().await()
    }

    companion object {
        private const val SEED_FLAG_DOC = "meta/seeded"
        private const val BAZAMS_SEED_FLAG_DOC = "meta/bazamsSeeded"
    }
}
