import { For, createBinding, createState, onCleanup } from "ags"
import { Gtk } from "ags/gtk4"
import GLib from "gi://GLib?version=2.0"
import Gio from "gi://Gio?version=2.0"
import AstalTray from "gi://AstalTray?version=0.1"
import tray from "../lib/tray"

function copyMenuModel(model: Gio.MenuModel | null): Gio.Menu | null {
  if (!model) return null
  const menu = Gio.Menu.new()
  for (let i = 0, n = model.get_n_items(); i < n; ++i) {
    const item = Gio.MenuItem.new_from_model(model, i)
    const submenu = model.get_item_link(i, Gio.MENU_LINK_SUBMENU)
    if (submenu) {
      item.set_attribute_value(Gio.MENU_ATTRIBUTE_ACTION, null)
      item.set_submenu(copyMenuModel(submenu))
    }
    const section = model.get_item_link(i, Gio.MENU_LINK_SECTION)
    if (section) {
      item.set_section(copyMenuModel(section))
    }
    menu.append_item(item)
  }
  return menu
}

function TrayItem({ item }: { item: AstalTray.TrayItem }) {
  return (
    <box
      class="tray-item"
      tooltipText={item.tooltip_markup}
      $={(self: Gtk.Box) => {
        const popover = Gtk.PopoverMenu.new_from_model(
          copyMenuModel(item.menuModel),
        )
        popover.insert_action_group("dbusmenu", item.actionGroup)
        popover.set_parent(self)

        const safeCopy = () => copyMenuModel(item.menuModel)

        const actionHandler = item.connect(
          "notify::action-group",
          () => popover.insert_action_group("dbusmenu", item.actionGroup),
        )

        const left = Gtk.GestureClick.new()
        left.set_button(1)
        left.connect("pressed", () => item.activate(0, 0))
        self.add_controller(left)

        const right = Gtk.GestureClick.new()
        right.set_button(3)
        right.connect("pressed", () => {
          if (item.menuModel) {
            item.about_to_show()
            popover.set_menu_model(safeCopy())
            popover.popup()
          } else {
            item.secondary_activate(0, 0)
          }
        })
        self.add_controller(right)

        onCleanup(() => {
          item.disconnect(actionHandler)
          self.remove_controller(left)
          self.remove_controller(right)
          popover.unparent()
        })
      }}
    >
      <image gicon={createBinding(item, "gicon")} />
    </box>
  )
}

export function SystemTray() {
  const [trayVisible, setTrayVisible] = createState(false)

  return (
    <box class="system-tray" spacing={0}>
      <button
        class="tray-toggle"
        onClicked={() => setTrayVisible(!trayVisible.get())}
      >
        <label
          label={trayVisible((v) => (v ? "◀" : "▶"))}
        />
      </button>
      <box
        class="tray-items"
        visible={trayVisible}
        spacing={2}
        $={(self: Gtk.Box) => {
          const itemsHandler = tray.connect(
            "notify::items",
            () => GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
              self.queue_resize()
              return GLib.SOURCE_REMOVE
            }),
          )

          const notifyCleanup = trayVisible.subscribe(() => {
            if (trayVisible.get())
              GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
                self.queue_resize()
                return GLib.SOURCE_REMOVE
              })
          })

          onCleanup(() => {
            tray.disconnect(itemsHandler)
            notifyCleanup()
          })
        }}
      >
        <For each={createBinding(tray, "items")}>
          {(item) => <TrayItem item={item} />}
        </For>
      </box>
    </box>
  )
}
