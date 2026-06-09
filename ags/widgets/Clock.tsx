import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { createState, onCleanup } from "ags"
import { togglePanel, unseenDot, unseenCritical } from "./Notifications"

export function Clock() {
  const time = createPoll("", 1000, "date '+%I:%M %p'")
  const date = createPoll("", 60000, "date '+%a %b %d'")

  const [dotClass, setDotClass] = createState(
    !unseenDot.get() ? "notification-dot" :
    unseenCritical.get() ? "notification-dot active critical" :
    "notification-dot active"
  )

  const updateDot = () => {
    if (!unseenDot.get()) {
      setDotClass("notification-dot")
    } else if (unseenCritical.get()) {
      setDotClass("notification-dot active critical")
    } else {
      setDotClass("notification-dot active")
    }
  }

  onCleanup(unseenDot.subscribe(updateDot))
  onCleanup(unseenCritical.subscribe(updateDot))

  return (
    <button
      class="clock"
      halign={Gtk.Align.END}
      onClicked={() => togglePanel()}
    >
      <box spacing={8}>
        <label label={time} />
        <label label={date} />
        <label
          label="●"
          class={dotClass}
        />
      </box>
    </button>
  )
}
