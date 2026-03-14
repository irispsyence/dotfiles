import Gtk from "gi://Gtk?version=4.0"
import Gio from "gi://Gio"
import GLib from "gi://GLib"

const BACKLIGHT = "/sys/class/backlight/amdgpu_bl1"

function readInt(path: string): number {
  try {
    const [, bytes] = GLib.file_get_contents(path)
    return parseInt(new TextDecoder().decode(bytes).trim(), 10)
  } catch {
    return 0
  }
}

function getBrightness(): number {
  const current = readInt(`${BACKLIGHT}/brightness`)
  const max = readInt(`${BACKLIGHT}/max_brightness`)
  return max > 0 ? current / max : 0
}

function setBrightness(fraction: number) {
  const pct = Math.round(fraction * 100)
  try {
    Gio.Subprocess.new(["brightnessctl", "set", `${pct}%`], Gio.SubprocessFlags.NONE)
  } catch (e) {
    console.error("brightnessctl failed:", e)
  }
}

export default function BrightnessSlider() {
  return (
    <box cssClasses={["slider-row"]} spacing={10}>
      <label label="󰃟" cssClasses={["slider-icon"]} />
      <box hexpand={true} $={(self) => {
        const scale = new Gtk.Scale({
          orientation: Gtk.Orientation.HORIZONTAL,
          hexpand: true,
          drawValue: false,
        })
        scale.set_range(0, 1)
        scale.add_css_class("brightness-slider")
        scale.set_value(getBrightness())

        // React to external brightness changes (e.g. keyboard shortcuts)
        const monitor = Gio.File.new_for_path(`${BACKLIGHT}/brightness`)
          .monitor_file(Gio.FileMonitorFlags.NONE, null)

        let fromMonitor = false
        monitor.connect("changed", () => {
          fromMonitor = true
          scale.set_value(getBrightness())
          fromMonitor = false
        })

        scale.connect("value-changed", () => {
          if (!fromMonitor) setBrightness(scale.get_value())
        })

        scale.connect("destroy", () => monitor.cancel())
        self.append(scale)
      }} />
    </box>
  )
}
