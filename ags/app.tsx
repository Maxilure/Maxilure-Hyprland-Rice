import "./lib/jsx-ext"
import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./Bar"
import NotificationPopups from "./widgets/NotificationPopups"
import Notifications from "./widgets/Notifications"

app.start({
  css: style,
  main() {
    const dp3 = app.get_monitors().find((m) => m.connector === "DP-3")
    if (!dp3) return

    Bar(dp3)
    NotificationPopups(dp3)
    Notifications(dp3)
  },
})
