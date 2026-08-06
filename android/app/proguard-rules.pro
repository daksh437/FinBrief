# R8 rules for the release build.
#
# Debug builds don't shrink code, so anything here only ever matters in
# release — which is exactly why these bugs surface late.

# --- Room / WorkManager ---------------------------------------------------
#
# google_mobile_ads pulls in WorkManager, whose WorkDatabase is a Room
# database. Room finds its generated implementation by name at runtime
# (Class.forName(dbClass.getName() + "_Impl")), so once R8 renames that class
# the lookup fails and the app dies during startup with:
#
#   Unable to get provider androidx.startup.InitializationProvider
#   Caused by: Failed to create an instance of androidx.work.impl.WorkDatabase
#
# Reflection is invisible to R8, so the classes have to be kept explicitly.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.room.RoomDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.** { *; }
-keep class androidx.startup.** { *; }
-dontwarn androidx.work.**

# --- Firebase / Play services --------------------------------------------
#
# Crashlytics needs line numbers and source files to symbolicate a stack
# trace; without them release crash reports are unreadable.
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# --- Play Billing ---------------------------------------------------------
-keep class com.android.billingclient.** { *; }

# --- Flutter --------------------------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
