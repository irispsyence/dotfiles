import Gtk from "gi://Gtk?version=4.0"
import Gio from "gi://Gio"
import GLib from "gi://GLib"

// Talks directly to BlueZ over DBus — no external process needed
function getProxy(): Gio.DBusProxy | null {
  try {
    return Gio.DBusProxy.new_sync(
      Gio.DBus.system,
      Gio.DBusProxyFlags.NONE,
      null,
      "org.bluez",
      "/org/bluez/hci0",
      "org.bluez.Adapter1",
      null
    )
  } catch (e) {
    console.error("BlueZ DBus proxy failed:", e)
    return null
  }
}

function getPowered(proxy: Gio.DBusProxy): boolean {
  return proxy.get_cached_property("Powered")?.get_boolean() ?? false
}

function setPowered(proxy: Gio.DBusProxy, on: boolean) {
  proxy.call(
    "org.freedesktop.DBus.Properties.Set",
    new GLib.Variant("(ssv)", ["org.bluez.Adapter1", "Powered", new GLib.Variant("b", on)]),
    Gio.DBusCallFlags.NONE,
    -1,
    null,
    null
  )
}

export default function BluetoothToggle() {
  const proxy = getProxy()

  return (
    <box cssClasses={["toggle-item"]} orientation={Gtk.Orientation.HORIZONTAL} spacing={8} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} hexpand={true}>
      <label label="󰂯" cssClasses={["toggle-icon"]} valign={Gtk.Align.CENTER} />
      <box valign={Gtk.Align.CENTER} $={(self) => {
        const sw = new Gtk.Switch()
        sw.add_css_class("pill-toggle")

        if (proxy) {
          sw.active = getPowered(proxy)
          let fromService = false

          proxy.connect("g-properties-changed", (_: Gio.DBusProxy, changed: GLib.Variant) => {
            const val = changed.lookup_value("Powered", null)
            if (val) {
              fromService = true
              sw.active = val.get_boolean()
              fromService = false
            }
          })

          sw.connect("notify::active", () => {
            if (!fromService) setPowered(proxy, sw.active)
          })
        }

        self.append(sw)
      }} />
    </box>
  )
}
