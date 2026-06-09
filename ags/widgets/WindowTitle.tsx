import { Gtk } from "ags/gtk4"
import { createComputed } from "ags"
import { activeTitle } from "../lib/hyprland"

export function WindowTitle() {
  const title = createComputed(() => activeTitle())

  return (
    <box class="window-title" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
      <label
        class="window-title-text"
        label={title}
        halign={Gtk.Align.CENTER}
        ellipsize={3}
        maxWidthChars={30}
      />
    </box>
  )
}
