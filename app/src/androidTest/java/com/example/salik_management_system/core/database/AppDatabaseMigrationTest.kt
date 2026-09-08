package com.example.salik_management_system.core.database

import androidx.room.testing.MigrationTestHelper
import androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AppDatabaseMigrationTest {
    private val testDb = "migration-test"

    @get:Rule
    val helper: MigrationTestHelper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(),
        AppDatabase::class.java.canonicalName,
        FrameworkSQLiteOpenHelperFactory(),
    )

    @Test
    fun migrate1To2_preservesSaliksAndBuildsFtsIndex() {
        helper.createDatabase(testDb, 1).apply {
            execSQL(
                """
                INSERT INTO local_saliks (
                    salik_id, name, father_name, mobile_number, whatsapp_number,
                    area_id, address, gender_id, bazam_id, date_of_baith,
                    reference_name, is_nafi_asbat, is_sahib_e_mehfil,
                    created_date, modified_date, is_active, added_by_uid,
                    added_by_name, approval_status, approved_by_uid,
                    approved_by_name, approved_at, sync_status, local_updated_at
                ) VALUES (
                    's1', 'Ali Khan', 'Ahmed', '03001234567', '03001234567',
                    'area-1', 'Street 1', 'male', 'i-10', '2020-01-01',
                    'Ref', 0, 0, '2020-01-01', '2020-01-01', 1, 'u1',
                    'Admin', 'approved', '', '', '', 'synced', 1
                )
                """.trimIndent(),
            )
            execSQL(
                """
                INSERT INTO local_users (
                    uid, email, name, role, gender, password_hash, last_synced_at
                ) VALUES (
                    'u1', 'madmin@dev.cms.com', 'Admin', 'admin', 'Male', 'hash', 1
                )
                """.trimIndent(),
            )
            close()
        }

        val migrated = helper.runMigrationsAndValidate(testDb, 2, true, MIGRATION_1_2)

        migrated.query("SELECT COUNT(*) FROM local_saliks").use { cursor ->
            assertTrue(cursor.moveToFirst())
            assertEquals(1, cursor.getInt(0))
        }
        migrated.query("SELECT COUNT(*) FROM local_users").use { cursor ->
            assertTrue(cursor.moveToFirst())
            assertEquals(1, cursor.getInt(0))
        }
        migrated.query(
            """
            SELECT local_saliks.name FROM local_saliks
            JOIN saliks_fts ON local_saliks.rowid = saliks_fts.rowid
            WHERE saliks_fts MATCH 'Ali'
            """.trimIndent(),
        ).use { cursor ->
            assertTrue(cursor.moveToFirst())
            assertEquals("Ali Khan", cursor.getString(0))
        }

        migrated.close()
    }
}
