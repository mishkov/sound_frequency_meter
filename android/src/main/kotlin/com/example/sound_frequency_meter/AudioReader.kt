package com.example.sound_frequency_meter

import android.media.AudioRecord

class AudioReader(private val config: AudioReaderConfiguration, onData: (data: ByteArray) -> Unit) {

    private val recorder: AudioRecord = AudioRecord(
        AudioReaderConfiguration.audioSource,
        config.sampleRate,
        AudioReaderConfiguration.channelConfig,
        AudioReaderConfiguration.audioFormat,
        config.readsNumber,
    )

    private val runnable = Runnable {
        waitUntil(recorder.recordingState != AudioRecord.RECORDSTATE_RECORDING)

        val data = ByteArray(config.readsNumber)
        while (recorder.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
            recorder.read(data, 0, config.readsNumber)
            onData(data)
        }
    }

    private val thread = Thread(runnable)

    fun startStream() {
        recorder.startRecording()
        thread.start()
    }

    private fun waitUntil(condition: Boolean) {
        while(condition) {
            doNothing()
        }
    }

    private fun doNothing() {}

    fun stopStream() {
        recorder.stop()
    }

    fun release() {
        recorder.release()
    }
}