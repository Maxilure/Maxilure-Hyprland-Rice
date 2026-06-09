import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import AstalNotifd from "gi://AstalNotifd"
import { clearAll } from "../lib/notifd"
import Notification from "./Notification"
import {
  saveNotifications,
  loadNotifications,
  clearSavedNotifications,
  SavedNotification,
} from "../lib/persist"
import { For, createState, onCleanup } from "ags"

export const [panelVisible, setPanelVisible] = createState(false)
export const [dndEnabled, setDndEnabled] = createState(false)
export const [unseenDot, setUnseenDot] = createState(false)
export const [unseenCritical, setUnseenCritical] = createState(false)

export function togglePanel(): void {
  const wasClosed = !panelVisible.get()
  setPanelVisible((v) => !v)
  if (wasClosed) {
    setUnseenDot(false)
    setUnseenCritical(false)
  }
}

export function toggleDnd(): void {
  setDndEnabled((v) => !v)
}

export default function Notifications(monitor: Gdk.Monitor) {
  const notifd = AstalNotifd.get_default()

  const [liveNotifications, setLiveNotifications] = createState(
    new Array<AstalNotifd.Notification>(),
  )

  const [savedNotifications, setSavedNotifications] = createState(
    loadNotifications(),
  )

  const notifiedHandler = notifd.connect("notified", (_, id, replaced) => {
    const notification = notifd.get_notification(id)

    if (!panelVisible.get()) {
      setUnseenDot(true)
      if (notification.urgency === AstalNotifd.Urgency.CRITICAL) {
        setUnseenCritical(true)
      }
    }

    if (replaced && liveNotifications.get().some((n) => n.id === id)) {
      setLiveNotifications((ns) => ns.map((n) => (n.id === id ? notification : n)))
    } else {
      setLiveNotifications((ns) => [notification, ...ns])
    }
  })

  const resolvedHandler = notifd.connect("resolved", (_, id) => {
    setLiveNotifications((ns) => ns.filter((n) => n.id !== id))
  })

  // Save live notifications to disk when they change
  const unsubLive = liveNotifications.subscribe(() => {
    saveNotifications(liveNotifications.get())
  })

  onCleanup(() => {
    notifd.disconnect(notifiedHandler)
    notifd.disconnect(resolvedHandler)
    unsubLive()
  })

  const hasNotifications = liveNotifications.as((ns) => ns.length > 0)
  const hasSaved = savedNotifications.as((ns) => ns.length > 0)
  const hasAny = hasNotifications.as((live) => live || savedNotifications.get().length > 0)

  return (
    <window
      name="notifications-panel"
      class="notifications-panel"
      visible={panelVisible}
      gdkmonitor={monitor}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.RIGHT}
      widthRequest={380}
      heightRequest={400}
    >
      <box
        class="notifications-panel-inner"
        orientation={Gtk.Orientation.VERTICAL}
        widthRequest={380}
      >
        <box class="notifications-panel-header">
          <label
            class="notifications-panel-title"
            label="Notifications"
            halign={Gtk.Align.START}
            hexpand
          />
          <box spacing={6}>
            <button
              class={dndEnabled.as((v) => v ? "dnd-button active" : "dnd-button")}
              onClicked={() => toggleDnd()}
            >
              <label label={dndEnabled.as((v) => v ? "󰂛" : "󰂚")} />
            </button>
            <button
              class="notifications-panel-clear"
              visible={hasAny}
              onClicked={() => {
                clearAll()
                clearSavedNotifications()
                setSavedNotifications([])
              }}
            >
              <label label="Clear All" />
            </button>
          </box>
        </box>
        <box class="notifications-panel-separator" />
        <scrolledwindow
          class="notifications-panel-scroll"
          visible={hasAny}
          hscrollbarPolicy={Gtk.PolicyType.NEVER}
          vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
          heightRequest={350}
        >
          <box
            class="notifications-panel-list"
            orientation={Gtk.Orientation.VERTICAL}
            spacing={8}
          >
            <For each={liveNotifications}>
              {(notification) => (
                <Notification notification={notification} showDismiss={true} />
              )}
            </For>
            {savedNotifications.get().length > 0 && liveNotifications.get().length > 0 && (
              <box class="notifications-panel-separator" />
            )}
            <For each={savedNotifications}>
              {(saved) => (
                <Notification
                  saved={saved}
                  showDismiss={true}
                  onDismiss={() => {
                    setSavedNotifications((ns) => ns.filter((s) => s.id !== saved.id))
                  }}
                />
              )}
            </For>
          </box>
        </scrolledwindow>
        <box
          class="notifications-panel-empty"
          visible={hasAny.as((v) => !v)}
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
          vexpand
        >
          <label label="No notifications" />
        </box>
      </box>
    </window>
  )
}
