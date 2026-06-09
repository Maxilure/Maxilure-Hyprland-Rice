import { Gtk } from "ags/gtk4"
import { createState, onCleanup } from "ags"
import { For } from "ags"
import tray, { renderIcon } from "../lib/tray"
import AstalTray from "gi://AstalTray"

export default function SystemTray() {
  const [open, setOpen] = createState(false)
  const [items, setItems] = createState<AstalTray.TrayItem[]>(tray.get_items())

  const update = () => {
    setItems(tray.get_items())
  }

  const id1 = tray.connect("item-added", update)
  const id2 = tray.connect("item-removed", update)
  onCleanup(() => {
    tray.disconnect(id1)
    tray.disconnect(id2)
  })

  const arrowLabel = open.as((v) => (v ? "▶" : "◀"))

  return (
    <box class="system-tray" spacing={4}>
      <button class="tray-toggle" onClicked={() => setOpen((v) => !v)}>
        <label label={arrowLabel} />
      </button>
      <scrolledwindow
        class="tray-scroll"
        visible={open}
        hscrollbar-policy={Gtk.PolicyType.AUTOMATIC}
        vscrollbar-policy={Gtk.PolicyType.NEVER}
        $={(self) => {
          const scrollCtrl = new Gtk.EventControllerScroll()
          scrollCtrl.set_flags(Gtk.EventControllerScrollFlags.VERTICAL)
          scrollCtrl.connect("scroll", (_ctrl, _dx, dy) => {
            const adj = self.hadjustment
            if (!adj) return false
            const step = dy * 30
            let newVal = adj.value + step
            newVal = Math.max(adj.lower, Math.min(adj.upper - adj.page_size, newVal))
            adj.value = newVal
            return true
          })
          self.add_controller(scrollCtrl)
        }}
      >
        <box class="tray-items" spacing={4}>
          <For each={items}>
            {(item) => {
              const icon = renderIcon(item) || (
                <label label={item.get_id()?.charAt(0).toUpperCase() || "?"} />
              )
              return (
                <button
                  class="tray-item"
                  onClicked={() => item.activate(0, 0)}
                  $={(self) => {
                    const rightClick = new Gtk.GestureClick()
                    rightClick.set_button(3)
                    rightClick.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
                    rightClick.connect("pressed", (_g, _n, x, y) => {
                      item.about_to_show()
                      const menuModel = item.get_menu_model()
                      if (menuModel) {
                        const actionGroup = item.get_action_group()
                        if (actionGroup) {
                          self.insert_action_group("dbusmenu", actionGroup)
                        }
                        const popover = new Gtk.PopoverMenu()
                        popover.menu_model = menuModel
                        popover.set_parent(self)
                        popover.popup()
                      } else {
                        item.secondary_activate(x, y)
                      }
                    })
                    self.add_controller(rightClick)
                  }}
                >
                  {icon}
                </button>
              )
            }}
          </For>
        </box>
      </scrolledwindow>
    </box>
  )
}
