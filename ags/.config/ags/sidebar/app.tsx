import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import Sidebar from "./widget/Sidebar"

function SidebarWindow() {
  return (
    <window
      name="sidebar"
      visible={false}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT}
      layer={Astal.Layer.OVERLAY}
      exclusivity={Astal.Exclusivity.IGNORE}
      marginTop={22}
      keymode={Astal.Keymode.ON_DEMAND}
      $={(win) => {
        const ctrl = new Gtk.EventControllerKey()
        ctrl.connect("key-pressed", (_: Gtk.EventControllerKey, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) { win.hide(); return true }
          return false
        })
        win.add_controller(ctrl)
      }}
    >
      <Sidebar />
    </window>
  ) as Gtk.Window
}

app.start({
  instanceName: "sidebar",
  css: "./style/sidebar.css",
  main() {
    app.add_window(SidebarWindow())
  },
})
