package com.scrapcal.scrapcal

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "com.scrapcal.scrapcal/gallery"
    private val storagePermissionCode = 2048

    private var pendingBytes: ByteArray? = null
    private var pendingFileName: String? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "savePngToGallery") {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName") ?: "SCRAPCAL_Resibo.png"
                    if (bytes == null || bytes.isEmpty()) {
                        result.error("INVALID_ARGS", "PNG image bytes are empty.", null)
                        return@setMethodCallHandler
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        saveWithMediaStore(bytes, fileName, result)
                    } else {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.WRITE_EXTERNAL_STORAGE
                        ) == PackageManager.PERMISSION_GRANTED
                        if (granted) {
                            saveLegacyPictures(bytes, fileName, result)
                        } else {
                            pendingBytes = bytes
                            pendingFileName = fileName
                            pendingResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                                storagePermissionCode
                            )
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == storagePermissionCode) {
            val bytes = pendingBytes
            val fileName = pendingFileName
            val result = pendingResult
            pendingBytes = null
            pendingFileName = null
            pendingResult = null

            if (result != null && bytes != null && fileName != null) {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    saveLegacyPictures(bytes, fileName, result)
                } else {
                    result.error("PERMISSION_DENIED", "Storage permission denied.", null)
                }
            }
        }
    }

    private fun saveWithMediaStore(
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result
    ) {
        try {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(
                    MediaStore.Images.Media.RELATIVE_PATH,
                    "${Environment.DIRECTORY_PICTURES}/SCRAPCAL"
                )
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            if (uri == null) {
                result.error("SAVE_FAILED", "Failed to create MediaStore entry.", null)
                return
            }

            resolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
                stream.flush()
            } ?: run {
                resolver.delete(uri, null, null)
                result.error("SAVE_FAILED", "Failed to open output stream.", null)
                return
            }

            val doneValues = ContentValues().apply {
                put(MediaStore.Images.Media.IS_PENDING, 0)
            }
            resolver.update(uri, doneValues, null, null)
            result.success("Pictures/SCRAPCAL/$fileName")
        } catch (e: Exception) {
            result.error("SAVE_FAILED", e.message ?: "Failed to save image.", null)
        }
    }

    @Suppress("DEPRECATION")
    private fun saveLegacyPictures(
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result
    ) {
        try {
            val picturesDir =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            val appDir = File(picturesDir, "SCRAPCAL")
            if (!appDir.exists()) {
                appDir.mkdirs()
            }
            val file = File(appDir, fileName)
            FileOutputStream(file).use { stream ->
                stream.write(bytes)
                stream.flush()
            }
            MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(file.absolutePath),
                arrayOf("image/png"),
                null
            )
            result.success(file.absolutePath)
        } catch (e: Exception) {
            result.error("SAVE_FAILED", e.message ?: "Failed to save image.", null)
        }
    }
}
