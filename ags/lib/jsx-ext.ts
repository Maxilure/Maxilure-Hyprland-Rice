import Gtk from "gi://Gtk?version=4.0"
import { intrinsicElements } from "gnim/gtk4/jsx-runtime"

Object.assign(intrinsicElements, {
  picture: Gtk.Picture,
  calendar: Gtk.Calendar,
  popover: Gtk.Popover,
  flowbox: Gtk.FlowBox,
})
