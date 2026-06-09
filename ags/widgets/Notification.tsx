import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import GLib from "gi://GLib"
import Gio from "gi://Gio"
import AstalNotifd from "gi://AstalNotifd"
import Pango from "gi://Pango"
import { SavedNotification } from "../lib/persist"

function isIcon(icon?: string | null) {
  const display = Gdk.Display.get_default()
  if (!display) return false
  const iconTheme = Gtk.IconTheme.get_for_display(display)
  return icon ? iconTheme.has_icon(icon) : false
}

function fileExists(path: string) {
  return GLib.file_test(path, GLib.FileTest.EXISTS)
}

function time(timestamp: number, format = "%H:%M") {
  return GLib.DateTime.new_from_unix_local(timestamp).format(format)!
}

function urgency(n: AstalNotifd.Notification | SavedNotification) {
  const { LOW, NORMAL, CRITICAL } = AstalNotifd.Urgency
  switch (n.urgency) {
    case LOW:
      return "low"
    case CRITICAL:
      return "critical"
    case NORMAL:
    default:
      return "normal"
  }
}

interface NotificationProps {
  notification?: AstalNotifd.Notification
  saved?: SavedNotification
  onClicked?: () => void
  showDismiss?: boolean
  onDismiss?: () => void
}

export default function Notification({ notification: n, saved, onClicked, showDismiss = false, onDismiss }: NotificationProps) {
  const data = n || saved!
  const isLive = Boolean(n)

  return (
    <box
      $={(self) => {
        if (onClicked && isLive) {
          const gesture = new Gtk.GestureClick()
          gesture.connect("pressed", () => onClicked())
          self.add_controller(gesture)
        }
      }}
      class={`notification ${urgency(data)}`}
      orientation={Gtk.Orientation.VERTICAL}
      widthRequest={350}
    >
      <box class="notification-header">
        <label
          class="notification-app-name"
          halign={Gtk.Align.START}
          hexpand
          ellipsize={Pango.EllipsizeMode.END}
          label={data.appName || "Unknown"}
        />
        <label
          class="notification-time"
          label={time(data.time)}
        />
        {showDismiss && (
          <button
            class="notification-dismiss"
            onClicked={() => {
              if (isLive) {
                n!.dismiss()
              }
              onDismiss?.()
            }}
          >
            <label label="✕" />
          </button>
        )}
      </box>
      <box class="notification-content">
        {data.image && fileExists(data.image) && (
          <box class="notification-image-box" valign={Gtk.Align.START} widthRequest={48} heightRequest={48}>
            <picture
              class="notification-image"
              file={Gio.File.new_for_path(data.image)}
              contentFit={Gtk.ContentFit.COVER}
            />
          </box>
        )}
        {!fileExists(data.image || "") && isIcon(data.image) && (
          <box class="notification-icon-image" valign={Gtk.Align.START}>
            <image
              iconName={data.image}
              halign={Gtk.Align.CENTER}
              valign={Gtk.Align.CENTER}
              pixelSize={48}
            />
          </box>
        )}
        <box orientation={Gtk.Orientation.VERTICAL}>
          <label
            class="notification-summary"
            halign={Gtk.Align.START}
            xalign={0}
            label={data.summary}
            ellipsize={Pango.EllipsizeMode.END}
          />
          {data.body && (
            <label
              class="notification-body"
              wrap
              useMarkup
              halign={Gtk.Align.START}
              xalign={0}
              label={data.body}
            />
          )}
        </box>
      </box>
      {data.actions.length > 0 && isLive && (
        <box class="notification-actions">
          {data.actions.map(({ label, id }) => (
            <button
              hexpand
              onClicked={() => n!.invoke(id)}
            >
              <label label={label} halign={Gtk.Align.CENTER} hexpand />
            </button>
          ))}
        </box>
      )}
    </box>
  )
}
