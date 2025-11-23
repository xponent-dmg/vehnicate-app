package com.vehnicate.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    
    private var sensorEventChannel: SensorEventChannel? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup sensor event channel
        sensorEventChannel = SensorEventChannel(this)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SensorEventChannel.CHANNEL_NAME
        ).setStreamHandler(sensorEventChannel)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        sensorEventChannel = null
    }
}
