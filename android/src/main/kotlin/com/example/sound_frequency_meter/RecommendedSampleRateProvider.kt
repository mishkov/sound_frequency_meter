package com.example.sound_frequency_meter

import android.content.Context
import android.media.AudioManager

class RecommendedSampleRateProvider(private val context: Context) {
    fun get(): Int {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val sampleRate = audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE)

        return sampleRate.toInt()
    }
}