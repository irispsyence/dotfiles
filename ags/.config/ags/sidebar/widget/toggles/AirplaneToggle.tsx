import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib"

function isAirplaneModeOn(): boolean {
  try {
    const [, stdout] = GLib.spawn_command_line_sync("rfkill --json list")
    const json = JSON.parse(new TextDecoder().decode(stdout))
    const ifaces: any[] = json[""] ?? []
    return ifaces.length > 0 && ifaces.every((i: any) => i["soft"] === "blocked")
  } catch {
    return false
  }
}

export default function AirplaneToggle() {
  return (
    <box cssClasses={["toggle-item"]} orientation={Gtk.Orientation.HORIZONTAL} spacing={8} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} hexpand={true}>
      <label label="󰀝" cssClasses={["toggle-icon"]} valign={Gtk.Align.CENTER} />
      <box valign={Gtk.Align.CENTER} $={(self) => {
        const sw = new Gtk.Switch()
        sw.add_css_class("pill-toggle")
        sw.active = isAirplaneModeOn()

        sw.connect("notify::active", () => {
          const cmd = sw.active ? "rfkill block all" : "rfkill unblock all"
          GLib.spawn_command_line_async(cmd)
        })

        self.append(sw)
      }} />
    </box>
  )
}
