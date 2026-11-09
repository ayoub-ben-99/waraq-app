package com.waraq.rn

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
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
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.ScrollView
import android.widget.SeekBar
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
  private var darkMode = true
  private var pageScale = 1.0f
  private var pageCount = 0
  private val executor = Executors.newSingleThreadExecutor()
  private val main = Handler(Looper.getMainLooper())
  private lateinit var root: LinearLayout
  private lateinit var toolbar: LinearLayout
  private lateinit var pageScroll: ScrollView
  private lateinit var pageCanvas: PageCanvas
  private lateinit var pageLabel: TextView

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    bookId = intent.getIntExtra(EXTRA_BOOK_ID, 0)
    pageIndex = intent.getIntExtra(EXTRA_PAGE, 0)
    val path = intent.getStringExtra(EXTRA_PATH) ?: run { finish(); return }
    darkMode = getPreferences(MODE_PRIVATE).getBoolean(PREF_DARK, true)
    pageScale = getPreferences(MODE_PRIVATE).getFloat(PREF_SCALE, 1.0f)

    root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
    toolbar = buildToolbar()
    root.addView(toolbar, LinearLayout.LayoutParams(MATCH, dp(72)))
    pageCanvas = PageCanvas(this).apply { setOnSwipeListener { direction -> if (direction > 0) next() else previous() } }
    pageScroll = ScrollView(this).apply { isFillViewport = true; addView(pageCanvas, ViewGroup.LayoutParams(MATCH, ViewGroup.LayoutParams.WRAP_CONTENT)) }
    root.addView(pageScroll, LinearLayout.LayoutParams(MATCH, 0, 1f))
    setContentView(root)
    applyTheme()

    try {
      descriptor = ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY)
      renderer = PdfRenderer(descriptor!!)
      pageCount = renderer?.pageCount ?: 0
      if (pageCount <= 0) { finish(); return }
      pageIndex = pageIndex.coerceIn(0, pageCount - 1)
      renderPage()
    } catch (_: Exception) { finish() }
  }

  private fun buildToolbar(): LinearLayout {
    val bar = LinearLayout(this).apply { gravity = Gravity.CENTER_VERTICAL; setPadding(dp(8), dp(8), dp(8), dp(8)) }
    val close = iconButton("إغلاق القارئ") { finish() }
    val navigation = iconButton("التنقل بين الصفحات") { showPageMenu() }
    val settings = iconButton("إعدادات القراءة") { showSettings() }
    val theme = iconButton("تبديل الوضع الداكن") { darkMode = !darkMode; getPreferences(MODE_PRIVATE).edit().putBoolean(PREF_DARK, darkMode).apply(); applyTheme() }
    pageLabel = TextView(this).apply { textSize = 15f; gravity = Gravity.CENTER; setTypeface(null, 1) }
    bar.addView(close, cell()); bar.addView(navigation, cell()); bar.addView(pageLabel, LinearLayout.LayoutParams(0, MATCH_CONTENT, 1f)); bar.addView(theme, cell()); bar.addView(settings, cell())
    return bar
  }

  private fun iconButton(description: String, action: () -> Unit) = TextView(this).apply {
    text = when {
      description.contains("إغلاق") -> "×"
      description.contains("التنقل") -> "☰"
      description.contains("الوضع") -> "☾"
      else -> "⚙"
    }
    textSize = 25f; gravity = Gravity.CENTER; contentDescription = description
    setTextColor(Color.WHITE); setBackgroundColor(Color.TRANSPARENT); setPadding(dp(8), dp(4), dp(8), dp(4)); setOnClickListener { action() }
  }

  private fun showSettings() {
    val panel = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(20), dp(16), dp(20), dp(16)) }
    panel.addView(TextView(this).apply { text = "إعدادات القراءة"; textSize = 20f; setTypeface(null, 1) })
    panel.addView(TextView(this).apply { text = "حجم العرض"; textSize = 15f })
    panel.addView(SeekBar(this).apply {
      max = 2; progress = ((pageScale - 0.9f) / 0.15f).toInt().coerceIn(0, 2)
      setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
        override fun onProgressChanged(bar: SeekBar?, value: Int, fromUser: Boolean) { if (fromUser) { pageScale = 0.9f + value * 0.15f; getPreferences(MODE_PRIVATE).edit().putFloat(PREF_SCALE, pageScale).apply(); renderPage() } }
        override fun onStartTrackingTouch(bar: SeekBar?) {}
        override fun onStopTrackingTouch(bar: SeekBar?) {}
      })
    })
    panel.addView(TextView(this).apply { text = "نوع الخط\nيتبع خط المستند الأصلي في ملفات PDF"; textSize = 14f; setPadding(0, dp(12), 0, 0) })
    panel.addView(TextView(this).apply { text = "التباعد\nيمكن التمرير رأسياً داخل الصفحة بسلاسة"; textSize = 14f; setPadding(0, dp(12), 0, 0) })
    popup(panel)
  }

  private fun showPageMenu() {
    val panel = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(20), dp(16), dp(20), dp(16)) }
    panel.addView(TextView(this).apply { text = "التنقل بين الصفحات"; textSize = 20f; setTypeface(null, 1) })
    val label = TextView(this).apply { text = "الصفحة ${pageIndex + 1} من $pageCount"; textSize = 15f; gravity = Gravity.CENTER }
    val seek = SeekBar(this).apply { max = (pageCount - 1).coerceAtLeast(0); progress = pageIndex }
    seek.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
      override fun onProgressChanged(bar: SeekBar?, value: Int, fromUser: Boolean) { if (fromUser) label.text = "الصفحة ${value + 1} من $pageCount" }
      override fun onStartTrackingTouch(bar: SeekBar?) {}
      override fun onStopTrackingTouch(bar: SeekBar?) { pageIndex = bar?.progress ?: pageIndex; renderPage() }
    })
    panel.addView(label); panel.addView(seek); popup(panel)
  }

  private fun popup(panel: View) { PopupWindow(panel, dp(300), ViewGroup.LayoutParams.WRAP_CONTENT, true).apply { setBackgroundDrawable(android.graphics.drawable.ColorDrawable(if (darkMode) Color.rgb(38, 49, 41) else Color.rgb(248, 242, 229))); elevation = dp(8).toFloat(); showAtLocation(root, Gravity.TOP or Gravity.END, dp(12), dp(78)) } }

  private fun applyTheme() {
    val background = if (darkMode) Color.rgb(16, 19, 16) else Color.rgb(245, 239, 223)
    val bar = if (darkMode) Color.rgb(38, 49, 41) else Color.rgb(232, 224, 203)
    window.statusBarColor = bar; window.navigationBarColor = background; root.setBackgroundColor(background); toolbar.setBackgroundColor(bar); pageScroll.setBackgroundColor(background); pageCanvas.setReaderBackground(background); pageLabel.setTextColor(if (darkMode) Color.WHITE else Color.rgb(39, 82, 65))
  }

  private fun next() { if (pageIndex < pageCount - 1) { pageIndex++; renderPage() } }
  private fun previous() { if (pageIndex > 0) { pageIndex--; renderPage() } }

  private fun renderPage() {
    val pdf = renderer ?: return
    val index = pageIndex
    executor.execute {
      try {
        page?.close(); page = pdf.openPage(index); val current = page ?: return@execute
        val width = maxOf(1, (resources.displayMetrics.widthPixels * pageScale).toInt())
        val height = maxOf(1, (width * current.height.toFloat() / current.width).toInt())
        val nextBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888); nextBitmap.eraseColor(Color.WHITE); current.render(nextBitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
        main.post { if (isFinishing || isDestroyed) { nextBitmap.recycle(); return@post }; val old = bitmap; bitmap = nextBitmap; pageCanvas.setPage(nextBitmap); pageScroll.post { pageScroll.scrollTo(0, 0) }; old?.recycle(); pageLabel.text = "الصفحة ${index + 1} من $pageCount"; ReaderEvents.emit("onProgress", Bundle().apply { putInt("bookId", bookId); putInt("page", index); putInt("offset", 0); putInt("pageCount", pageCount) }) }
      } catch (_: Exception) { }
    }
  }

  override fun onBackPressed() { finish() }
  override fun onDestroy() { super.onDestroy(); if (!closed) { closed = true; ReaderEvents.emit("onReaderClosed", Bundle()) }; try { page?.close() } catch (_: Exception) {}; try { renderer?.close() } catch (_: Exception) {}; try { descriptor?.close() } catch (_: Exception) {}; bitmap?.recycle(); executor.shutdownNow() }
  private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
  private fun cell() = LinearLayout.LayoutParams(dp(48), MATCH_CONTENT)
  companion object {
    private const val MATCH = ViewGroup.LayoutParams.MATCH_PARENT; private const val MATCH_CONTENT = ViewGroup.LayoutParams.WRAP_CONTENT; private const val EXTRA_BOOK_ID = "bookId"; private const val EXTRA_PATH = "path"; private const val EXTRA_PAGE = "page"; private const val PREF_DARK = "reader_dark"; private const val PREF_SCALE = "reader_scale"
    fun start(context: Context, bookId: Int, path: String, page: Int) { context.startActivity(Intent(context, WaraqPdfReaderActivity::class.java).apply { putExtra(EXTRA_BOOK_ID, bookId); putExtra(EXTRA_PATH, path); putExtra(EXTRA_PAGE, page); if (context !is Activity) addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }) }
  }
}

private class PageCanvas(context: Context) : View(context) {
  private var page: Bitmap? = null; private var readerBackground = Color.rgb(16, 19, 16); private val paint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG); private var onSwipe: ((Int) -> Unit)? = null; private var downX = 0f; private var downY = 0f
  fun setPage(value: Bitmap) { page = value; layoutParams = layoutParams.apply { height = value.height }; requestLayout(); invalidate() }
  fun setReaderBackground(value: Int) { readerBackground = value; invalidate() }
  fun setOnSwipeListener(listener: (Int) -> Unit) { onSwipe = listener }
  override fun onDraw(canvas: Canvas) { canvas.drawColor(readerBackground); page?.let { canvas.drawBitmap(it, null, RectF(0f, 0f, width.toFloat(), it.height.toFloat() * width / it.width), paint) } }
  override fun onTouchEvent(event: MotionEvent): Boolean { when (event.actionMasked) { MotionEvent.ACTION_DOWN -> { downX = event.x; downY = event.y; parent.requestDisallowInterceptTouchEvent(true); return true }; MotionEvent.ACTION_UP -> { val dx = event.x - downX; val dy = event.y - downY; parent.requestDisallowInterceptTouchEvent(false); if (kotlin.math.abs(dx) > 80f && kotlin.math.abs(dx) > kotlin.math.abs(dy)) onSwipe?.invoke(if (dx < 0) 1 else -1); return true } }; return true }
}
