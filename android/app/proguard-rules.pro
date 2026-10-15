# WorkManager (pulled in by better_player_plus) creates its Room database
# reflectively. Without this, R8 strips WorkDatabase_Impl's no-arg
# constructor and release builds crash at startup in InitializationProvider.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { <init>(); }
