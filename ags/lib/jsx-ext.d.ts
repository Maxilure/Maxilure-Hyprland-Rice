import Gtk from "gi://Gtk?version=4.0"

type CCProps<T, P> = import("gnim").CCProps<T, P>

declare global {
  namespace JSX {
    interface IntrinsicElements {
      picture: CCProps<Gtk.Picture, Partial<Gtk.Picture.ConstructorProps>>
      calendar: CCProps<Gtk.Calendar, {
        day?: number
        month?: number
        year?: number
        showDayNames?: boolean
        showHeading?: boolean
        showWeekNumbers?: boolean
        onDaySelected?: () => void
      }>
      popover: CCProps<Gtk.Popover, Partial<Gtk.Popover.ConstructorProps>>
      flowbox: CCProps<Gtk.FlowBox, Partial<Gtk.FlowBox.ConstructorProps>>
    }
  }
}
