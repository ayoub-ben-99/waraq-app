package com.waraq.rn

import android.content.ContentResolver
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.Bundle
import android.os.ParcelFileDescriptor
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.security.MessageDigest
import java.util.UUID

class WaraqNativeModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("WaraqNative")
    Events("onProgress", "onHighlightAdded", "onEntryRequested", "onReaderClosed")

    OnCreate {
      ReaderEvents.sink = { name, payload -> sendEvent(name, payload) }
    }

    OnDestroy {
      ReaderEvents.sink = null
    }

    AsyncFunction("importPdf") { uri: String ->
      val context = appContext.reactContext ?: throw IllegalStateException("no-context")
      importPdf(context.contentResolver, Uri.parse(uri), context.filesDir)
    }

    AsyncFunction("extractCover") { path: String, bookId: Int ->
      val context = appContext.reactContext ?: throw IllegalStateException("no-context")
      extractCover(File(path), context.filesDir, bookId)
    }

    AsyncFunction("openReader") { bookId: Int, path: String, lastPage: Int, _: String ->
      val context = appContext.currentActivity ?: appContext.reactContext ?: throw IllegalStateException("no-context")
      WaraqPdfReaderActivity.start(context, bookId, path, lastPage)
    }

    AsyncFunction("clearOcrCache") {
      val context = appContext.reactContext ?: throw IllegalStateException("no-context")
      clearOcrCache(context.filesDir)
    }

    // يُصيّر صفحة PDF إلى ملف PNG مؤقت ويعيد مساره بأبعادها.
    // يُستخدم من قارئ واجهة React Native للتمرير العمودي والتقليب الأفقي.
    AsyncFunction("renderPage") { path: String, page: Int, width: Int, invert: Boolean ->
      val context = appContext.reactContext ?: throw IllegalStateException("no-context")
      renderPage(context, File(path), page, width, invert)
    }

    // يستخرج نص صفحة عبر PdfBox-Android مع تخزينه في ملف نصي جانبي.
    AsyncFunction("pageText") { path: String, page: Int ->
      val context = appContext.reactContext ?: throw IllegalStateException("no-context")
      pageText(context, File(path), page)
    }
  }

  private fun importPdf(resolver: ContentResolver, uri: Uri, filesDir: File): Map<String, Any> {
    val dir = File(filesDir, "pdfs").apply { mkdirs() }
    val name = displayName(resolver, uri)
    val target = File(dir, UUID.randomUUID().toString().replace("-", "") + ".pdf")
    try {
      resolver.openInputStream(uri)?.use { input -> copy(input, target) }
        ?: throw IllegalArgumentException("stream-unavailable")
      if (target.length() == 0L) throw IllegalArgumentException("pdf-empty")
      val pageCount = pageCount(target)
      if (pageCount <= 0) throw IllegalArgumentException("pdf-unreadable")
      return mapOf(
        "absolutePath" to target.absolutePath,
        "relativePath" to "pdfs/${target.name}",
        "displayName" to name,
        "sha256" to sha256(target),
        "pageCount" to pageCount,
        "sizeBytes" to target.length(),
      )
    } catch (error: Exception) {
      target.delete()
      throw error
    }
  }

  private fun extractCover(source: File, filesDir: File, bookId: Int): String? {
    val dir = File(filesDir, "covers").apply { mkdirs() }
    val target = File(dir, "cover_$bookId.png")
    ParcelFileDescriptor.open(source, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
      PdfRenderer(descriptor).use { renderer ->
        if (renderer.pageCount <= 0) return null
        renderer.openPage(0).use { page ->
          val width = 600
          val height = maxOf(1, (width * page.height.toFloat() / page.width).toInt())
          val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
          bitmap.eraseColor(Color.WHITE)
          page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
          FileOutputStream(target).use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 90, out)
          }
          bitmap.recycle()
        }
      }
    }
    return "covers/${target.name}"
  }

  private fun pageCount(file: File): Int {
    ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
      PdfRenderer(descriptor).use { renderer -> return renderer.pageCount }
    }
  }

  private fun copy(input: InputStream, target: File) {
    FileOutputStream(target).use { output ->
      input.copyTo(output, 8192)
      output.fd.sync()
    }
  }

  private fun displayName(resolver: ContentResolver, uri: Uri): String {
    var raw: String? = null
    resolver.query(uri, null, null, null, null)?.use { cursor ->
      if (cursor.moveToFirst()) {
        val index = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
        if (index >= 0 && !cursor.isNull(index)) raw = cursor.getString(index)
      }
    }
    var name = raw?.substringAfterLast('/')?.substringAfterLast('\\')?.trim().orEmpty()
    if (name.lowercase().endsWith(".pdf")) name = name.dropLast(4)
    return name.ifEmpty { "PDF" }
  }

  private fun sha256(file: File): String {
    val digest = MessageDigest.getInstance("SHA-256")
    file.inputStream().use { input ->
      val buffer = ByteArray(8192)
      while (true) {
        val read = input.read(buffer)
        if (read <= 0) break
        digest.update(buffer, 0, read)
      }
    }
    return digest.digest().joinToString("") { "%02x".format(it) }
  }

  private fun clearOcrCache(filesDir: File): Int {
    val dir = File(filesDir, "ocr-cache")
    if (!dir.exists()) return 0
    var count = 0
    dir.walkBottomUp().forEach { file ->
      if (file.isFile) {
        if (file.delete()) count++
      } else {
        file.delete()
      }
    }
    return count
  }

  private fun renderPage(context: android.content.Context, source: File, page: Int, width: Int, invert: Boolean): Map<String, Any?> {
    if (!source.exists()) throw IllegalArgumentException("pdf-missing")
    val safeWidth = width.coerceIn(120, 2048)
    val dir = File(context.cacheDir, "page-cache/${source.nameWithoutExtension}").apply { mkdirs() }
    val target = File(dir, "p${page}-w${safeWidth}-${if (invert) "i" else "n"}.png")
    var outWidth = 0
    var outHeight = 0
    if (!target.exists()) {
      ParcelFileDescriptor.open(source, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
        PdfRenderer(descriptor).use { renderer ->
          if (page < 0 || page >= renderer.pageCount) throw IllegalArgumentException("page-out-of-range")
          renderer.openPage(page).use { pdfPage ->
            outWidth = safeWidth
            outHeight = maxOf(1, (safeWidth * pdfPage.height.toFloat() / pdfPage.width).toInt())
            val bitmap = Bitmap.createBitmap(outWidth, outHeight, Bitmap.Config.ARGB_8888)
            bitmap.eraseColor(Color.WHITE)
            pdfPage.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
            val finalBitmap = if (invert) invertBitmap(bitmap) else bitmap
            FileOutputStream(target).use { output ->
              finalBitmap.compress(Bitmap.CompressFormat.PNG, 88, output)
            }
            finalBitmap.recycle()
          }
        }
      }
    } else {
      val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
      BitmapFactory.decodeFile(target.absolutePath, options)
      outWidth = options.outWidth
      outHeight = options.outHeight
    }
    return mapOf(
      "uri" to Uri.fromFile(target).toString(),
      "width" to outWidth,
      "height" to outHeight,
    )
  }

  /** عكس ألوان الصفحة للوضع الداكن: الأبيض يصير داكنًا والنص فاتحًا بتناسق. */
  private fun invertBitmap(source: Bitmap): Bitmap {
    val matrix = ColorMatrix(
      floatArrayOf(
        -1f, 0f, 0f, 0f, 255f,
        0f, -1f, 0f, 0f, 255f,
        0f, 0f, -1f, 0f, 255f,
        0f, 0f, 0f, 1f, 0f,
      ),
    )
    val paint = Paint().apply { colorFilter = ColorMatrixColorFilter(matrix) }
    val result = Bitmap.createBitmap(source.width, source.height, Bitmap.Config.ARGB_8888)
    Canvas(result).drawBitmap(source, 0f, 0f, paint)
    source.recycle()
    return result
  }

  private fun pageText(context: android.content.Context, source: File, page: Int): String {
    if (!source.exists()) throw IllegalArgumentException("pdf-missing")
    ensurePdfBox(context)
    val dir = File(context.filesDir, "pdf-text/${source.nameWithoutExtension}").apply { mkdirs() }
    val target = File(dir, "p${page}.txt")
    if (!target.exists()) {
      val text = PDDocument.load(source).use { document ->
        if (page < 0 || page >= document.numberOfPages) throw IllegalArgumentException("page-out-of-range")
        val stripper = PDFTextStripper().apply {
          startPage = page + 1
          endPage = page + 1
          sortByPosition = true
        }
        stripper.getText(document)
      }
      if (text.isBlank()) throw IllegalArgumentException("page-no-text")
      target.writeText(text)
    }
    return target.readText()
  }

  private fun ensurePdfBox(context: android.content.Context) {
    PDFBoxResourceLoader.init(context.applicationContext)
  }
}
