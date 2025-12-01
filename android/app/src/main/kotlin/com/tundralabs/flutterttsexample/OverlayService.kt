package com.tundralabs.flutterttsexample

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import androidx.core.app.NotificationCompat

class OverlayService : Service() {
    companion object {
        const val ACTION_SHOW = "ACTION_SHOW_MASK"
        const val ACTION_HIDE = "ACTION_HIDE_MASK"
        const val EXTRA_HEIGHT_DP = "EXTRA_HEIGHT_DP"
        const val EXTRA_ALPHA = "EXTRA_ALPHA"
        private const val CHANNEL_ID = "overlay_mask_channel"
        private const val NOTIF_ID = 1001
    }

    private var wm: WindowManager? = null
    private var maskView: View? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        startAsForeground()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHOW -> showMask(
                heightDp = intent.getIntExtra(EXTRA_HEIGHT_DP, 80),
                alpha = intent.getIntExtra(EXTRA_ALPHA, 230)
            )
            ACTION_HIDE -> hideMask()
        }
        return START_STICKY
    }

    private fun startAsForeground() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Overlay Mask",
                NotificationManager.IMPORTANCE_MIN
            )
            nm.createNotificationChannel(channel)
        }
        val notif: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("遮挡条正在运行")
            .setContentText("点击返回应用可自动关闭")
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setOngoing(true)
            .build()
        startForeground(NOTIF_ID, notif)
    }

    private fun showMask(heightDp: Int, alpha: Int) {
        if (maskView != null) return
        val heightPx = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            heightDp.toFloat(),
            resources.displayMetrics
        ).toInt()

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            heightPx,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.OPAQUE
        )
        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.alpha = 1f

        val view = View(this)
        // 改为白色不透明遮挡条（确保不透明：背景alpha=255，窗口alpha=1f）
        val cd = android.graphics.drawable.ColorDrawable(android.graphics.Color.WHITE)
        cd.alpha = 255
        view.background = cd
        view.alpha = 1f

        try {
            wm?.addView(view, params)
            maskView = view
        } catch (_: Exception) {
        }
    }

    private fun hideMask() {
        maskView?.let {
            try {
                wm?.removeView(it)
            } catch (_: Exception) { }
        }
        maskView = null
        stopSelf()
    }

    override fun onDestroy() {
        hideMask()
        super.onDestroy()
    }
}

