import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { Workspaces } from "./widgets/Workspaces"
import { SystemTray } from "./widgets/SystemTray"
import { Clock } from "./widgets/Clock"
import { WindowTitle } from "./widgets/WindowTitle"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name="bar"
      class="bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox class="centerbox">
        <box $type="start" halign={Gtk.Align.START}>
          <Workspaces />
        </box>
        <box $type="center" halign={Gtk.Align.CENTER}>
          <WindowTitle />
        </box>
        <box $type="end" halign={Gtk.Align.END}>
          <SystemTray />
          <Clock />
        </box>
      </centerbox>
    </window>
  )
}
