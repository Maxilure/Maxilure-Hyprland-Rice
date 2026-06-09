import { Gtk } from "ags/gtk4"
import { createComputed } from "ags"
import { workspaces, activeId, switchWorkspace } from "../lib/hyprland"

export function Workspaces() {
  return (
    <box class="workspaces" valign={Gtk.Align.CENTER} halign={Gtk.Align.START} spacing={0}>
      {Array.from({ length: 10 }, (_, i) => i + 1).map((id) => {
        const isActive = createComputed(() => activeId() === id)
        const isOccupied = createComputed(() =>
          workspaces().some((w) => w.id === id && w.windows > 0),
        )
        const isVisible = createComputed(() => isActive() || isOccupied())
        const btnClass = createComputed(() => {
          const classes: string[] = []
          if (isActive()) classes.push("active")
          if (isOccupied()) classes.push("occupied")
          return classes.join(" ")
        })

        return (
          <button
            class={btnClass}
            visible={isVisible}
            hexpand={false}
            tooltipText={`Workspace ${id}`}
            onClicked={() => switchWorkspace(id)}
          >
            <label
              label={String(id)}
              halign={Gtk.Align.CENTER}
              valign={Gtk.Align.CENTER}
            />
          </button>
        )
      })}
    </box>
  )
}
