# Flutter's Gradle plugin supplies the rules the engine and plugins need.
# The embedding references Play Core (deferred components) classes that this
# app does not ship; silence R8's missing-class errors for them.
-dontwarn com.google.android.play.core.**
