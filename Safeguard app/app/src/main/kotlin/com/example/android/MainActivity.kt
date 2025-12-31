package com.example.android

import android.os.Bundle
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "sendSms"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val messenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (messenger != null) {
            MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "send" -> {
                        val phone = call.argument<String>("phone")
                        val message = call.argument<String>("message")
                        if (phone != null && message != null) {
                            sendSMS(phone, message)
                            result.success(null)
                        } else {
                            result.error("INVALID_ARGUMENTS", "Phone number or message is null", null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }

    private fun sendSMS(phoneNumber: String, message: String) {
        try {
            println("MainActivity: Attempting to send SMS to $phoneNumber")
            println("MainActivity: Message: $message")
            
            val smsManager = SmsManager.getDefault()
            
            // Split message if it's too long for a single SMS
            val parts = smsManager.divideMessage(message)
            if (parts.size > 1) {
                println("MainActivity: Message split into ${parts.size} parts")
                smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
            } else {
                smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            }
            
            println("MainActivity: SMS sent successfully to $phoneNumber")
        } catch (e: SecurityException) {
            println("MainActivity: SecurityException - SMS permission not granted: ${e.message}")
            e.printStackTrace()
        } catch (e: Exception) {
            println("MainActivity: Exception while sending SMS: ${e.message}")
            e.printStackTrace()
        }
    }
}
