pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Shared notification service. Wraps Quickshell's NotificationServer and exposes
// a persistent history (max 50), DND state, and toast signals. Because it
// is a singleton it is instantiated once and shared across every monitor's bar.
Item {
    id: root

    // Do-Not-Disturb: suppresses toasts (the center still collects them).
    property bool dnd: false

    // Persistent history array — [{notifId, key, app, appIcon, summary, body, time}, ...]
    // newest first, max 50 entries. Backed by notifications-history.json.
    property var history: []

    // Emitted when a new notification arrives and should pop a toast.
    signal toastRequested(var notif, string histKey)
    // Emitted when a notification arrives while DND is on (toast suppressed).
    signal toastSuppressed()

    // Keys of notifications not yet seen (panel opened) or dismissed via toast click.
    property var unreadKeys: []
    property bool hasUrgentUnread: false

    function _recompute() {
        if (unreadKeys.length === 0) { hasUrgentUnread = false; return }
        var ks = {}
        for (var i = 0; i < unreadKeys.length; i++) ks[unreadKeys[i]] = true
        var u = false
        for (var j = 0; j < history.length; j++) {
            if (ks[history[j].key] && (history[j].urgency || 0) >= 2) { u = true; break }
        }
        hasUrgentUnread = u
    }

    function markRead(key) {
        unreadKeys = unreadKeys.filter(function(k) { return k !== key })
        _recompute()
    }

    function markAllRead() { unreadKeys = []; hasUrgentUnread = false }

    // ── Persistence ──────────────────────────────────────────────────────
    readonly property string _histFile: "/home/user/.config/quickshell/notifications-history.json"

    FileView {
        id: _histFileView
        path: root._histFile
        printErrors: false
        onLoaded: {
            var data = null
            try { data = JSON.parse(text()) } catch(e) {}
            var loaded = []
            if (Array.isArray(data)) {
                loaded = data  // legacy format: bare array
            } else if (data && Array.isArray(data.history)) {
                loaded = data.history
                if (typeof data.dnd === "boolean") root.dnd = data.dnd
            }
            var merged = root.history.concat(loaded)
            if (merged.length > 50) merged = merged.slice(0, 50)
            root.history = merged
        }
    }

    function saveHistory() {
        _histFileView.setText(JSON.stringify({ dnd: root.dnd, history: root.history }))
    }

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: (n) => {
            n.tracked = true
            var entry = {
                notifId: n.id,
                key: n.id + "_" + Date.now(),
                app: n.appName || "Notification",
                appIcon: n.appIcon || "",
                summary: n.summary || "",
                body: n.body || "",
                time: Date.now(),
                urgency: n.urgency || 0
            }
            var h = [entry].concat(root.history)
            if (h.length > 50) h = h.slice(0, 50)
            root.history = h
            root.saveHistory()
            root.unreadKeys = [entry.key].concat(root.unreadKeys)
            root._recompute()
            if (root.dnd) root.toastSuppressed()
            else root.toastRequested(n, entry.key)
        }
    }

    // Relative time string from an epoch-ms timestamp.
    function relTimeOf(ms, now) {
        var s = Math.floor((now - ms) / 1000)
        if (s < 60) return "now"
        var m = Math.floor(s / 60); if (m < 60) return m + "m"
        var h = Math.floor(m / 60); if (h < 24) return h + "h"
        return Math.floor(h / 24) + "d"
    }

    function dismissFromHistory(key) {
        // Also dismiss from live server if still tracked this session
        for (var i = 0; i < root.history.length; i++) {
            if (root.history[i].key === key) {
                var nid = root.history[i].notifId
                var vals = server.trackedNotifications.values
                for (var j = 0; j < vals.length; j++) {
                    if (vals[j].id === nid) { vals[j].dismiss(); break }
                }
                break
            }
        }
        root.history = root.history.filter(function(h) { return h.key !== key })
        root.markRead(key)
        root.saveHistory()
    }

    function clearAll() {
        var items = []
        var vals = server.trackedNotifications.values
        for (var i = 0; i < vals.length; i++) items.push(vals[i])
        for (var j = 0; j < items.length; j++) items[j].dismiss()
        root.history = []
        root.markAllRead()
        root.saveHistory()
    }

    function toggleDnd() { dnd = !dnd; saveHistory() }

    // ── Per-app presentation ─────────────────────────────────────────────
    function tintFor(app) {
        var a = (app || "").toLowerCase()
        if (a.indexOf("discord") >= 0) return "#89b4fa"
        if (a.indexOf("spotify") >= 0 || a.indexOf("music") >= 0) return "#a6e3a1"
        if (a.indexOf("mail") >= 0 || a.indexOf("thunder") >= 0) return "#cba6f7"
        if (a.indexOf("screenshot") >= 0 || a.indexOf("shot") >= 0) return "#94e2d5"
        if (a.indexOf("system") >= 0 || a.indexOf("battery") >= 0 || a.indexOf("power") >= 0) return "#fab387"
        var palette = ["#89b4fa", "#a6e3a1", "#fab387", "#cba6f7", "#94e2d5"]
        var h = 0
        for (var i = 0; i < a.length; i++) h = (h * 31 + a.charCodeAt(i)) >>> 0
        return palette[h % palette.length]
    }

    function letterFor(app) {
        var s = (app || "?").trim()
        return s.length ? s[0].toUpperCase() : "?"
    }
}
