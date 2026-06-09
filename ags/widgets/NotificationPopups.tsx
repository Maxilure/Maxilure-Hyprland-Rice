import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import AstalNotifd from "gi://AstalNotifd"
import Notification from "./Notification"
import { panelVisible, dndEnabled } from "./Notifications"
import { createState, For, onCleanup } from "ags"
import GLib from "gi://GLib?version=2.0"

export default function NotificationPopups(monitor: Gdk.Monitor) {
  const notifd = AstalNotifd.get_default()

  const [notifications, setNotifications] = createState(
    new Array<AstalNotifd.Notification>(),
  )

  const notifiedHandler = notifd.connect("notified", (_, id, replaced) => {
    if (panelVisible.get() || dndEnabled.get()) return

    const notification = notifd.get_notification(id)

    if (replaced && notifications.get().some((n) => n.id === id)) {
      setNotifications((ns) => ns.map((n) => (n.id === id ? notification : n)))
    } else {
      setNotifications((ns) => [notification, ...ns])
    }

    // Auto-dismiss from popup after 5 seconds
    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 5000, () => {
      setNotifications((ns) => ns.filter((n) => n.id !== id))
      return GLib.SOURCE_REMOVE
    })
  })

  const resolvedHandler = notifd.connect("resolved", (_, id) => {
    setNotifications((ns) => ns.filter((n) => n.id !== id))
  })

  onCleanup(() => {
    notifd.disconnect(notifiedHandler)
    notifd.disconnect(resolvedHandler)
  })

  return (
    <window
      $={(self) => onCleanup(() => self.destroy())}
      class="notification-popups"
      gdkmonitor={monitor}
      visible={notifications((ns) => ns.length > 0)}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
    >
      <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
        <For each={notifications}>
          {(notification) => (
            <Notification
              notification={notification}
              onClicked={() => {
                // Just remove from popup, don't dismiss from notifd
                setNotifications((ns) => ns.filter((n) => n.id !== notification.id))
              }}
            />
          )}
        </For>
      </box>
    </window>
  )
}
