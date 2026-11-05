package com.waraq.rn

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.pdf.PdfRenderer
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import java.io.File
import java.util.concurrent.Executors

class WaraqPdfReaderActivity : Activity() {
  private var renderer: PdfRenderer? = null
  private var descriptor: ParcelFileDescriptor? = null
  private var page: PdfRenderer.Page? = null
  private var bitmap: Bitmap? = null
  private var pageIndex = 0
  private var bookId = 0
  private var closed = false
  private val executor = Executors.newSingleThreadExecutor()
  private val main = Handler(Looper.getMainLooper())
  private lateinit var canvasView: PageCanvas
  private lateinit var pageLabel: TextView

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    bookId = intent.getIntExtra(EXTRA_BOOK_ID, 0)
    pageIndex = intent.getIntExtra(EXTRA_PAGE, 0)
    val path = intent.getStringExtra(EXTRA_PATH) ?: run {
      finish()
      return
    }
    window.statusBarColor = Color.rgb(16, 19, 16)
    window.navigationBarColor = Color.rgb(16, 19, 16)
    val root = LinearLayout(this).apply {
      orientation = LinearLayout.VERTICAL
      setBackgroundColor(Color.rgb(16, 19, 16))
    }
    val toolbar = LinearLayout(this).apply {
      orientation = LinearLayout.HORIZONTAL
      gravity = Gravity.CENTER_VERTICAL
      setPadding(24, 12, 24, 12)
    }
    val close = Button(this).apply {
      text = "إغلاق"
      setTextColor(Color.WHITE)
      setBackgroundColor(Color.TRANSPARENT)
      setOnClickListener { finish() }
    }
    pageLabel = TextView(this).apply {
      setTextColor(Color.WHITE)
      textSize = 15f
      gravity = Gravity.CENTER
    }
    toolbar.addView(close, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
    toolbar.addView(pageLabel, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 2f))
    toolbar.addView(View(this), LinearLayout.LayoutParams(0, 1, 1f))
    root.addView(toolbar, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))

    canvasView = PageCanvas(this)
    canvasView.setOnSwipeListener { direction ->
      if (direction > 0) next() else previous()
    }
    root.addView(canvasView, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))

    val navigation = LinearLayout(this).apply {
      orientation = LinearLayout.HORIZONTAL
      gravity = Gravity.CENTER
      setPadding(24, 8, 24, 24)
    }
    val previous = Button(this).apply {
      text = "السابقة"
      setOnClickListener { previous() }
    }
    val next = Button(this).apply {
      text = "التالية"
      setOnClickListener { next() }
    }
    navigation.addView(previous, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
    navigation.addView(View(this), LinearLayout.LayoutParams(24, 1))
    navigation.addView(next, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
    root.addView(navigation, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
    setContentView(root)

    try {
      descriptor = ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY)
      renderer = PdfRenderer(descriptor!!)
      val count = renderer?.pageCount ?: 0
      if (count <= 0) {
        finish()
        return
      }
      pageIndex = pageIndex.coerceIn(0, count - 1)
      renderPage()
    } catch (_: Exception) {
      finish()
    }
  }

  private fun next() {
    val count = renderer?.pageCount ?: return
    if (pageIndex < count - 1) {
      pageIndex += 1
      renderPage()
    }
  }

  private fun previous() {
    if (pageIndex > 0) {
      pageIndex -= 1
      renderPage()
    }
  }

  private fun renderPage() {
    val renderer = renderer ?: return
    val index = pageIndex
    executor.execute {
      try {
        page?.close()
        page = renderer.openPage(index)
        val current = page ?: return@execute
        val width = maxOf(1, resources.displayMetrics.widthPixels)
        val height = maxOf(1, (width * current.height.toFloat() / current.width).toInt())
        val nextBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        nextBitmap.eraseColor(Color.WHITE)
        current.render(nextBitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
        main.post {
          if (isFinishing || isDestroyed) {
            nextBitmap.recycle()
            return@post
          }
          val old = bitmap
          bitmap = nextBitmap
          canvasView.setPage(nextBitmap)
          old?.recycle()
          val count = renderer.pageCount
          pageLabel.text = "الصفحة ${index + 1} من $count"
          ReaderEvents.emit("onProgress", Bundle().apply {
            putInt("bookId", bookId)
            putInt("page", index)
            putInt("offset", 0)
            putInt("pageCount", count)
          })
        }
      } catch (_: Exception) {
      }
    }
  }

  override fun onBackPressed() {
    finish()
  }

  override fun onDestroy() {
    super.onDestroy()
    if (!closed) {
      closed = true
      ReaderEvents.emit("onReaderClosed", Bundle())
    }
    try {
      page?.close()
    } catch (_: Exception) {
    }
    page = null
    try {
      renderer?.close()
    } catch (_: Exception) {
    }
    renderer = null
    try {
      descriptor?.close()
    } catch (_: Exception) {
    }
    descriptor = null
    bitmap?.recycle()
    bitmap = null
    executor.shutdownNow()
  }

  companion object {
    private const val EXTRA_BOOK_ID = "bookId"
    private const val EXTRA_PATH = "path"
    private const val EXTRA_PAGE = "page"

    fun start(context: Context, bookId: Int, path: String, page: Int) {
      val intent = Intent(context, WaraqPdfReaderActivity::class.java).apply {
        putExtra(EXTRA_BOOK_ID, bookId)
        putExtra(EXTRA_PATH, path)
        putExtra(EXTRA_PAGE, page)
        if (context !is Activity) addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      }
      context.startActivity(intent)
    }
  }
}

private class PageCanvas(context: Context) : View(context) {
  private var page: Bitmap? = null
  private val paint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
  private var onSwipe: ((Int) -> Unit)? = null
  private var downX = 0f

  fun setPage(value: Bitmap) {
    page = value
    invalidate()
  }

  fun setOnSwipeListener(listener: (Int) -> Unit) {
    onSwipe = listener
  }

  override fun onDraw(canvas: Canvas) {
    super.onDraw(canvas)
    canvas.drawColor(Color.rgb(16, 19, 16))
    val source = page ?: return
    val scale = minOf(width.toFloat() / source.width, height.toFloat() / source.height)
    val targetWidth = source.width * scale
    val targetHeight = source.height * scale
    val left = (width - targetWidth) / 2f
    val top = (height - targetHeight) / 2f
    canvas.drawBitmap(source, null, RectF(left, top, left + targetWidth, top + targetHeight), paint)
  }

  override fun onTouchEvent(event: MotionEvent): Boolean {
    when (event.actionMasked) {
      MotionEvent.ACTION_DOWN -> {
        downX = event.x
        return true
      }
      MotionEvent.ACTION_UP -> {
        val delta = event.x - downX
        if (delta > 80f) onSwipe?.invoke(-1)
        else if (delta < -80f) onSwipe?.invoke(1)
        return true
      }
    }
    return super.onTouchEvent(event)
  }
}
