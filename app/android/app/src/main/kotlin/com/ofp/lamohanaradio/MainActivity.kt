package com.ofp.lamohanaradio

import com.ryanheise.audioservice.AudioServiceActivity

// Hereda de AudioServiceActivity, no de FlutterActivity: es lo que permite al
// servicio de audio volver a esta pantalla al tocar la notificación y
// compartir el motor de Flutter con él.
class MainActivity : AudioServiceActivity()
