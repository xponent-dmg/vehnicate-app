package com.vehnicate.app

import android.content.Context
import io.flutter.plugin.common.EventChannel

/**
 * Event channel handler for streaming sensor data to Flutter.
 * Manages the lifecycle of sensor data streaming.
 */
class SensorEventChannel(private val context: Context) : EventChannel.StreamHandler {

    private var sensorManager: VehnicateSensorManager? = null
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        const val CHANNEL_NAME = "vehnicate/sensors"
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events

        // Create and start sensor manager
        sensorManager = VehnicateSensorManager(context) { packet ->
            // Send data to Flutter
            eventSink?.success(packet.toMap())
        }

        // Check if sensors are available
        if (sensorManager?.areSensorsAvailable() == true) {
            sensorManager?.startSensors()
        } else {
            eventSink?.error(
                "SENSOR_NOT_AVAILABLE",
                "Required sensors are not available on this device",
                null
            )
        }
    }

    override fun onCancel(arguments: Any?) {
        sensorManager?.stopSensors()
        sensorManager?.cleanup()
        sensorManager = null
        eventSink = null
    }
}
