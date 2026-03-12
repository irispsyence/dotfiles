import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import Calendar from "./widget/Calendar"
import { prev, next } from "./widget/calendarState"

function CalendarWindow() {
  return (
    <window
      name="calendar"
      visible={false}
      anchor={Astal.WindowAnchor.TOP}
      layer={Astal.Layer.OVERLAY}
      exclusivity={Astal.Exclusivity.IGNORE}
      marginTop={26}
      keymode={Astal.Keymode.ON_DEMAND}
      $={(win) => {
        const ctrl = new Gtk.EventControllerKey()
        ctrl.connect("key-pressed", (_: Gtk.EventControllerKey, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) { win.hide(); return true }
          if (keyval === Gdk.KEY_Left) { prev(); return true }
          if (keyval === Gdk.KEY_Right) { next(); return true }
          return false
        })
        win.add_controller(ctrl)
      }}
    >
      <Calendar />
    </window>
  ) as Gtk.Window
}

app.start({
  css: "./style/calendar.css",
  main() {
    app.add_window(CalendarWindow())
  },
})
