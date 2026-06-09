import GLib from "gi://GLib"
import AstalNotifd from "gi://AstalNotifd"

const CACHE_DIR = GLib.get_user_cache_dir() + "/ags"
const NOTIF_FILE = CACHE_DIR + "/notifications.json"

export interface SavedNotification {
  id: number
  appName: string
  appIcon: string
  desktopEntry: string
  summary: string
  body: string
  image: string
  time: number
  urgency: number
  actions: Array<{ label: string; id: string }>
}

function ensureCacheDir(): void {
  if (!GLib.file_test(CACHE_DIR, GLib.FileTest.EXISTS)) {
    GLib.mkdir_with_parents(CACHE_DIR, 0o755)
  }
}

export function saveNotifications(notifications: AstalNotifd.Notification[]): void {
  ensureCacheDir()

  const data: SavedNotification[] = notifications.map((n) => ({
    id: n.id,
    appName: n.appName || "",
    appIcon: n.appIcon || "",
    desktopEntry: n.desktopEntry || "",
    summary: n.summary || "",
    body: n.body || "",
    image: n.image || "",
    time: n.time,
    urgency: n.urgency,
    actions: n.actions.map((a) => ({ label: a.label, id: a.id })),
  }))

  const json = JSON.stringify(data, null, 2)
  GLib.file_set_contents(NOTIF_FILE, json)
}

export function loadNotifications(): SavedNotification[] {
  if (!GLib.file_test(NOTIF_FILE, GLib.FileTest.EXISTS)) {
    return []
  }

  const [ok, contents] = GLib.file_get_contents(NOTIF_FILE)
  if (!ok || !contents) {
    return []
  }

  try {
    const text = new TextDecoder().decode(contents)
    const data = JSON.parse(text) as SavedNotification[]
    // Filter to last 24 hours only
    const cutoff = Math.floor(Date.now() / 1000) - 86400
    return data.filter((n) => n.time > cutoff)
  } catch {
    return []
  }
}

export function clearSavedNotifications(): void {
  if (GLib.file_test(NOTIF_FILE, GLib.FileTest.EXISTS)) {
    GLib.unlink(NOTIF_FILE)
  }
}
