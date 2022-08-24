package com.example.sound_frequency_meter

import android.content.Context
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.mishkov.kiss_fft_jni.KISSFastFourierTransformer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.sqrt
import io.flutter.plugin.common.MethodChannel.Result as MethodCallResult

class SoundFrequencyMeterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private var context: Context? = null

    private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())
    private var uiThreadEvents: EventSink? = null

    private var audioReader: AudioReader? = null

    private var eventChannel: EventChannel? = null

    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            SOUND_FREQUENCY_METER_METHOD_CHANNEL_NAME
        )
        channel!!.setMethodCallHandler(this)

        eventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            SOUND_FREQUENCY_METER_EVENT_CHANNEL_NAME
        )

        eventChannel!!.setStreamHandler(this)


        context = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel?.setStreamHandler(null)
        channel?.setMethodCallHandler(null)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodCallResult) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventSink?) {
        uiThreadEvents = events

        val mapArguments = arguments as Map<*, *>
        val sampleRate = mapArguments["sampleRate"] as Int?
            ?: if (context != null) {
                RecommendedSampleRateProvider(context!!).get()
            } else {
                throw Exception("Sample rate is null and context is null. No sample rate to start record")
            }
        val readsNumber = mapArguments["readsNumber"] as Int
        val config = AudioReaderConfiguration(sampleRate, readsNumber)

        audioReader = AudioReader(config) { data ->

            val dataWithZero = ByteArray(data.size * 4)
            for (i in data.indices) {
                dataWithZero[i * 2] = data[i]
                dataWithZero[i * 2 + 1] = 0
                dataWithZero[i * 2 + 2] = 0
                dataWithZero[i * 2 + 3] = 0
            }

            val result =
                KISSFastFourierTransformer().transformRealOptimisedForward(dataWithZero.map { e -> e.toDouble() }
                    .toDoubleArray())

            val firstIndex = 0
            var maxAmplitude: Double =
                sqrt(result[firstIndex].real * result[firstIndex].real * result[firstIndex].imaginary * result[firstIndex].imaginary)
            var maxAmplitudeIndex = firstIndex
            for (i in firstIndex until result.size) {
                val nextAmplitude: Double =
                    sqrt(result[i].real * result[i].real * result[i].imaginary * result[i].imaginary)
                if (nextAmplitude > maxAmplitude) {
                    maxAmplitude = nextAmplitude
                    maxAmplitudeIndex = i
                }
            }

            val frequency: Double =
                (config.sampleRate.toDouble() / (data.size * 2)) * maxAmplitudeIndex

            try {
                uiThreadHandler.post {
                    uiThreadEvents!!.success(frequency)
                }
            } catch (e: IllegalArgumentException) {
                // TODO("Make better logging")
                println("sound_frequency_meter: " + frequency.hashCode() + " is not valid!")
                uiThreadHandler.post {
                    uiThreadEvents!!.error("-1", "Invalid Data", e)
                }
            }
        }

        audioReader?.startStream()
    }

    override fun onCancel(arguments: Any?) {
        audioReader?.stopStream()
        audioReader?.release()
    }

    companion object {
        private const val SOUND_FREQUENCY_METER_EVENT_CHANNEL_NAME = "frequency_stream"
        private const val SOUND_FREQUENCY_METER_METHOD_CHANNEL_NAME = "sound_frequency_meter"
    }
}
