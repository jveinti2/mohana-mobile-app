## Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Just Audio
-keep class com.google.android.exoplayer2.** { *; }

## Audio service (servicio en primer plano y notificación de medios).
## Sus clases solo se nombran desde el manifiesto, y androidx.media usa
## reflexión para el MediaSession: sin esto, R8 podría dejar la release sin
## notificación — y eso no se ve compilando en depuración.
-keep class com.ryanheise.audioservice.** { *; }
-keep class androidx.media.** { *; }
-dontwarn com.ryanheise.audioservice.**

## Play Core (deferred components)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
