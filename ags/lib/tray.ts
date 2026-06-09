import AstalTray from "gi://AstalTray"
import Gdk from "gi://Gdk?version=4.0"
import Gtk from "gi://Gtk?version=4.0"

const tray = AstalTray.get_default()

export function renderIcon(item: AstalTray.TrayItem, size = 20): Gtk.Image | null {
  // Try pixbuf first (best quality)
  const pixbuf = item.get_icon_pixbuf()
  if (pixbuf) {
    try {
      const texture = Gdk.Texture.new_for_pixbuf(pixbuf)
      const img = Gtk.Image.new_from_paintable(texture)
      // can't set pixelSize on paintable images, use widthRequest
      img.widthRequest = size
      img.heightRequest = size
      return img
    } catch {}
  }

  // Try themed icon name
  const iconName = item.get_icon_name()
  if (iconName) {
    const display = Gdk.Display.get_default()
    if (display) {
      const theme = Gtk.IconTheme.get_for_display(display)
      if (theme.has_icon(iconName)) {
        const img = Gtk.Image.new_from_icon_name(iconName)
        img.pixelSize = size
        return img
      }
    }
  }

  // Try gicon
  const gicon = item.get_gicon()
  if (gicon) {
    try {
      const img = Gtk.Image.new_from_gicon(gicon)
      img.pixelSize = size
      return img
    } catch {}
  }

  return null
}

export default tray
