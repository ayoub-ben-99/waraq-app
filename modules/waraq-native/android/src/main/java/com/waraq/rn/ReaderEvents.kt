package com.waraq.rn

import android.os.Bundle

object ReaderEvents {
  @Volatile
  var sink: ((String, Bundle) -> Unit)? = null

  fun emit(name: String, payload: Bundle) {
    sink?.invoke(name, payload)
  }
}
