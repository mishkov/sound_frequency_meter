package com.example.sound_frequency_meter

import android.media.AudioRecord
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.mishkov.kiss_fft_jni.KISSFastFourierTransformer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import kotlin.math.sqrt

class SoundFrequencyMeterPlugin: FlutterPlugin, EventChannel.StreamHandler {

  private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())
  private var uiThreadEvents: EventSink? = null

  private var audioReader : AudioReader? = null

  private var eventChannel : EventChannel? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, SOUND_FREQUENCY_METER_EVENT_CHANNEL_NAME)
    eventChannel!!.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    eventChannel?.setStreamHandler(null)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    uiThreadEvents = events

    val mapArguments = arguments as Map<*, *>
    val sampleRate = mapArguments["sampleRate"] as Int
    val numberOfReads = AudioRecord.getMinBufferSize(sampleRate, AudioReaderConfiguration.channelConfig, AudioReaderConfiguration.audioFormat,);
    val config = AudioReaderConfiguration(sampleRate, numberOfReads)

    audioReader = AudioReader(config) { data ->

      val result = KISSFastFourierTransformer().transformRealOptimisedForward(data.map { e -> e.toDouble() }.toDoubleArray());

      val firstIndex = 0;
      var maxAmplitude : Double = sqrt(result[firstIndex].real*result[firstIndex].real * result[firstIndex].imaginary*result[firstIndex].imaginary)
      var maxAmplitudeIndex = firstIndex
      for (i in firstIndex until result.size) {
        val nextAmplitude : Double = sqrt(result[i].real*result[i].real * result[i].imaginary*result[i].imaginary)
        if (nextAmplitude > maxAmplitude) {
          maxAmplitude = nextAmplitude;
          maxAmplitudeIndex = i;
        }
      }

      val frequency : Double = (config.sampleRate.toDouble() / data.size) * maxAmplitudeIndex;

      try {
        uiThreadHandler.post( Runnable {
          uiThreadEvents!!.success(frequency)
        })
      } catch (e: IllegalArgumentException) {
        // TODO("Make better logging")
        println("sound_frequency_meter: " + frequency.hashCode() + " is not valid!")
        uiThreadHandler.post(Runnable {
          uiThreadEvents!!.error("-1", "Invalid Data", e)
        })
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
  }
}
