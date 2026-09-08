package com.example.salik_management_system.core.database

import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

private fun tableExists(db: SupportSQLiteDatabase, tableName: String): Boolean {
    db.query(
        """
        SELECT name FROM sqlite_master
        WHERE type = 'table' AND name = ?
        """.trimIndent(),
        arrayOf(tableName),
    ).use { cursor ->
        return cursor.moveToFirst()
    }
}

private fun createSaliksFts(db: SupportSQLiteDatabase) {
    db.execSQL(
        """
        CREATE VIRTUAL TABLE IF NOT EXISTS `saliks_fts` USING FTS4(
            `name` TEXT NOT NULL,
            `mobile_number` TEXT NOT NULL,
            `father_name` TEXT NOT NULL,
            `date_of_baith` TEXT NOT NULL,
            content=`local_saliks`
        )
        """.trimIndent(),
    )
    db.execSQL(
        """
        CREATE TRIGGER IF NOT EXISTS room_fts_content_sync_saliks_fts_BEFORE_UPDATE
        BEFORE UPDATE ON `local_saliks`
        BEGIN
            DELETE FROM `saliks_fts` WHERE `docid`=OLD.`rowid`;
        END
        """.trimIndent(),
    )
    db.execSQL(
        """
        CREATE TRIGGER IF NOT EXISTS room_fts_content_sync_saliks_fts_BEFORE_DELETE
        BEFORE DELETE ON `local_saliks`
        BEGIN
            DELETE FROM `saliks_fts` WHERE `docid`=OLD.`rowid`;
        END
        """.trimIndent(),
    )
    db.execSQL(
        """
        CREATE TRIGGER IF NOT EXISTS room_fts_content_sync_saliks_fts_AFTER_UPDATE
        AFTER UPDATE ON `local_saliks`
        BEGIN
            INSERT INTO `saliks_fts`(
                `docid`, `name`, `mobile_number`, `father_name`, `date_of_baith`
            ) VALUES (
                NEW.`rowid`, NEW.`name`, NEW.`mobile_number`, NEW.`father_name`, NEW.`date_of_baith`
            );
        END
        """.trimIndent(),
    )
    db.execSQL(
        """
        CREATE TRIGGER IF NOT EXISTS room_fts_content_sync_saliks_fts_AFTER_INSERT
        AFTER INSERT ON `local_saliks`
        BEGIN
            INSERT INTO `saliks_fts`(
                `docid`, `name`, `mobile_number`, `father_name`, `date_of_baith`
            ) VALUES (
                NEW.`rowid`, NEW.`name`, NEW.`mobile_number`, NEW.`father_name`, NEW.`date_of_baith`
            );
        END
        """.trimIndent(),
    )
}

val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        if (!tableExists(db, "saliks_fts")) {
            createSaliksFts(db)
        }
        db.execSQL("INSERT INTO saliks_fts(saliks_fts) VALUES('rebuild')")
    }
}
