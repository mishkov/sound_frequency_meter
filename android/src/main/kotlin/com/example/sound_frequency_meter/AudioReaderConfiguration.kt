package com.example.sound_frequency_meter

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder

class AudioReaderConfiguration(val sampleRate: Int, val readsNumber: Int) {

    init {
        checkSampleRate(sampleRate)
        checkReadsNumberFor(sampleRate, readsNumber)
    }

    companion object {
        const val audioSource = MediaRecorder.AudioSource.DEFAULT
        const val channelConfig = AudioFormat.CHANNEL_IN_MONO
        const val audioFormat = AudioFormat.ENCODING_PCM_8BIT

        /**
         * Checks the sample rate and return min number of reads for default configuration with specified
         * sampleRate.
         *
         * Use it to p
         */
        fun getMinReadsNumber(sampleRate: Int): Int {
            checkSampleRate(sampleRate)
            return AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
        }

        /**
         * Throws IncorrectSampleRateException if sample rate is incorrect
         */
        private fun checkSampleRate(sampleRate: Int) {
            val minReadsNumber =
                AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
            if (minReadsNumber == 0) {
                throw IncorrectSampleRateException("Sample Rate $sampleRate is not compatible with $channelConfig channel config and $audioFormat audio format.\nTry to change sampleRate or channelConfig or audioFormat")
            }
        }

        /**
         * Throws IncorrectReadsNumberException if number of reads is incorrect
         */
        private fun checkReadsNumberFor(sampleRate: Int, readsNumber: Int) {
            val minReadsNumber =
                AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
            if (readsNumber < minReadsNumber) {
                throw IncorrectReadsNumberException("Incorrect readsNumber: $readsNumber.\nMin compatible for current configuration if $minReadsNumber")
            }
        }
    }
}
