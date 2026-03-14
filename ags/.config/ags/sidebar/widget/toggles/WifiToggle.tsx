import Gtk from "gi://Gtk?version=4.0"
import Network from "gi://AstalNetwork"

// Requires: paru -S astal-network

export default function WifiToggle() {
  const network = Network.get_default()

  return (
    <box cssClasses={["toggle-item"]} orientation={Gtk.Orientation.HORIZONTAL} spacing={8} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} hexpand={true}>
      <label label="󰖩" cssClasses={["toggle-icon"]} valign={Gtk.Align.CENTER} />
      <box valign={Gtk.Align.CENTER} $={(self) => {
        const sw = new Gtk.Switch()
        sw.add_css_class("pill-toggle")

        if (network.wifi) {
          sw.active = network.wifi.enabled
          let fromService = false
          network.wifi.connect("notify::enabled", () => {
            fromService = true
            sw.active = network.wifi!.enabled
            fromService = false
          })
          sw.connect("notify::active", () => {
            if (!fromService && network.wifi) network.wifi.enabled = sw.active
          })
        }

        self.append(sw)
      }} />
    </box>
  )
}
