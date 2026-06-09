import AstalNotifd from "gi://AstalNotifd"
import { createState } from "ags"

const notifd = AstalNotifd.get_default()

const [notifications, setNotifications] = createState(
  new Array<AstalNotifd.Notification>(),
)

const notifiedHandler = notifd.connect("notified", (_, id, replaced) => {
  const notification = notifd.get_notification(id)

  if (replaced && notifications.get().some((n) => n.id === id)) {
    setNotifications((ns) => ns.map((n) => (n.id === id ? notification : n)))
  } else {
    setNotifications((ns) => [notification, ...ns])
  }
})

const resolvedHandler = notifd.connect("resolved", (_, id) => {
  setNotifications((ns) => ns.filter((n) => n.id !== id))
})

function dismiss(id: number): void {
  const n = notifications.get().find((n) => n.id === id)
  if (n) n.dismiss()
}

function clearAll(): void {
  for (const n of notifications.get()) {
    n.dismiss()
  }
}

export { notifications, dismiss, clearAll, notifd }
