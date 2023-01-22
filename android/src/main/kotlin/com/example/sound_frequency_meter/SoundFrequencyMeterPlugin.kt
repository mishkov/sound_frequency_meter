package com.example.sound_frequency_meter

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.mishkov.kiss_fft_jni.KISSFastFourierTransformer
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.absoluteValue
import kotlin.math.roundToInt
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

    private val frequenciesDivisionByColumn = listOf(
        FrequencyInterval(0.0, 250.0),
        FrequencyInterval(251.0, 300.0),
        FrequencyInterval(301.0, 450.0),
        FrequencyInterval(451.0, 480.0),
        FrequencyInterval(481.0, 620.0),
        FrequencyInterval(621.0, 800.0),
        FrequencyInterval(801.0, 1200.0),
        FrequencyInterval(1201.0, 20000.0),
    )

    private val columnHeight = 8

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

//            val dataWithZero = ByteArray(data.size * 4)
//            for (i in data.indices) {
//                dataWithZero[i * 2] = data[i]
//                dataWithZero[i * 2 + 1] = 0
//                dataWithZero[i * 2 + 2] = 0
//                dataWithZero[i * 2 + 3] = 0
//            }

            val result =
                KISSFastFourierTransformer().transformRealOptimisedForward(data.map { e -> e.toDouble() }
                    .toDoubleArray())

            val frequencyStep = config.sampleRate.toDouble() / (data.size)
            val startFrequencyInHz = 20
            val endFrequencyInHz = 16000
            val firstIndex = (startFrequencyInHz / frequencyStep).roundToInt()
            val endIndex = (endFrequencyInHz / frequencyStep).roundToInt()

            var maxAmplitude: Double =
                sqrt(result[firstIndex].real * result[firstIndex].real * result[firstIndex].imaginary * result[firstIndex].imaginary)
            var maxAmplitudeIndex = firstIndex

            val resultData = DoubleArray(frequenciesDivisionByColumn.size)
            var columnIndex = 0
            var frequencySum = 0.0
            var frequenciesCount = 0
            for (i in firstIndex until endIndex) {
                val nextAmplitude: Double =
                    sqrt(result[i].real * result[i].real + result[i].imaginary * result[i].imaginary)

                val frequency = (config.sampleRate.toDouble() / data.size) * i
                while (frequency > frequenciesDivisionByColumn[columnIndex].end) {
                    if (frequenciesCount != 0 && columnIndex < resultData.size) {
                        resultData[columnIndex] = frequencySum /  frequenciesCount
                    }

                    if ((columnIndex + 1) < frequenciesDivisionByColumn.size) {
                        columnIndex++
                    } else {
                        break
                    }
                    frequencySum = 0.0
                    frequenciesCount = 0

                }

                val amplitudeThreshold= 30000
                val maxDrawableAmplitude = 120000

                if (nextAmplitude > amplitudeThreshold) {
                    frequencySum += ((nextAmplitude / maxDrawableAmplitude) * columnHeight)
                    frequenciesCount++
                }

                if (nextAmplitude > maxAmplitude) {
                    maxAmplitude = nextAmplitude
                    maxAmplitudeIndex = i
                }
            }
            if (frequenciesCount != 0 && columnIndex < resultData.size) {
                resultData[columnIndex] = frequencySum /  frequenciesCount
            }
  //          Log.d("sound_frequency_meter", "Max Amplitude is is ${maxAmplitude}")

//            val amplitudeThreshold = 140000000000
//            val frequency = if (maxAmplitude > amplitudeThreshold) {
//                (config.sampleRate.toDouble() / (data.size * 2)) * maxAmplitudeIndex
//            } else {
//                0.0
//            }

//            val frequency =
//                (config.sampleRate.toDouble() / (data.size * 2)) * maxAmplitudeIndex

            try {
                uiThreadHandler.post {
                    uiThreadEvents!!.success(resultData)
                }
            } catch (e: IllegalArgumentException) {
                // TODO("Make better logging")
                println("sound_frequency_meter: " + resultData.hashCode() + " is not valid!")
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

class FrequencyInterval(val begin: Double, val end: Double) {}