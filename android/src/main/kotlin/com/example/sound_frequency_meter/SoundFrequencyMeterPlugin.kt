package com.example.sound_frequency_meter

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import com.mishkov.kiss_fft_jni.KISSFastFourierTransformer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.sqrt

class SoundFrequencyMeterPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

  private val uiThreadHandler: Handler = Handler(Looper.getMainLooper())

  private lateinit var channel : MethodChannel

  private var eventSink: EventSink? = null

  private var recorder: AudioRecord? = null

  private var AUDIO_SOURCE = MediaRecorder.AudioSource.DEFAULT
  private var SAMPLE_RATE = 16000
  private var actualSampleRate = 0
  private var CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
  private var AUDIO_FORMAT = AudioFormat.ENCODING_PCM_8BIT
  private var actualBitDepth = 0
  private var BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)

  private var record = false

  private var isRecording = false

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {

    channel = MethodChannel(flutterPluginBinding.binaryMessenger,
      Companion.SOUND_FREQUENCY_METER_METHOD_CHANNEL_NAME
    )
    channel.setMethodCallHandler(this)

    val eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, SOUND_FREQUENCY_METER_EVENT_CHANNEL_NAME)
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events;
    // Try to initialize and start the recorder
    recorder =
      AudioRecord(AUDIO_SOURCE, SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT, BUFFER_SIZE)
    if (recorder!!.state != AudioRecord.STATE_INITIALIZED) {
      // TODO("Make error more informative")
      eventSink!!.error("-1", "PlatformError", null)
      return
    }

    recorder!!.startRecording()

    val runnable = Runnable {
      isRecording = true
      actualSampleRate = recorder!!.sampleRate
      actualBitDepth =
        if (recorder!!.audioFormat == AudioFormat.ENCODING_PCM_8BIT) 8 else 16

      // Wait until recorder is initialised
      while (recorder == null || recorder!!.recordingState != AudioRecord.RECORDSTATE_RECORDING);

      // Repeatedly push audio samples to stream
      while (record) {

        // Read audio data into new byte array
        val data = ByteArray(BUFFER_SIZE)
        recorder!!.read(data, 0, BUFFER_SIZE)

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

        val resultToSend : Double = (SAMPLE_RATE.toDouble() / data.size) * maxAmplitudeIndex;

        // push data into stream
        try {
          uiThreadHandler.post( Runnable {
            eventSink!!.success(resultToSend)
          })

        } catch (e: IllegalArgumentException) {
          println("mic_stream: " + resultToSend.hashCode() + " is not valid!")
          uiThreadHandler.post(Runnable {
            eventSink!!.error("-1", "Invalid Data", e)
          })

        }
      }
      isRecording = false
    }

    // Start runnable
    record = true
    Thread(runnable).start()
  }

  override fun onCancel(arguments: Any?) {
    TODO("Not yet implemented")
  }

  companion object {
    private const val SOUND_FREQUENCY_METER_METHOD_CHANNEL_NAME = "sound_frequency_meter"
    private const val SOUND_FREQUENCY_METER_EVENT_CHANNEL_NAME = "frequency_stream"
  }
}
