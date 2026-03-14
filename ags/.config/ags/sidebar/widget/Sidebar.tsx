import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib"
import WifiToggle from "./toggles/WifiToggle"
import BluetoothToggle from "./toggles/BluetoothToggle"
import AirplaneToggle from "./toggles/AirplaneToggle"
import VolumeSlider from "./sliders/VolumeSlider"
import MicSlider from "./sliders/MicSlider"
import BrightnessSlider from "./sliders/BrightnessSlider"
import PowerButtons from "./buttons/PowerButtons"

function getFigletTitle(): string {
  try {
    const [, stdout] = GLib.spawn_command_line_sync("figlet -f small Settings")
    return new TextDecoder().decode(stdout).trimEnd()
  } catch {
    return "Settings"
  }
}

const figletTitle = getFigletTitle()

export default function Sidebar() {
  return (
    <box cssClasses={["sidebar"]} orientation={Gtk.Orientation.VERTICAL} spacing={16}>

      {/* ── Title ── */}
      <label label={figletTitle} cssClasses={["sidebar-title"]} halign={Gtk.Align.CENTER} />

      {/* ── Toggles ── */}
      <box cssClasses={["toggle-row"]} spacing={8} homogeneous={true}>
        <WifiToggle />
        <BluetoothToggle />
        <AirplaneToggle />
      </box>

      {/* ── Sliders ── */}
      <box cssClasses={["slider-stack"]} orientation={Gtk.Orientation.VERTICAL} spacing={12}>
        <VolumeSlider />
        <MicSlider />
        <BrightnessSlider />
      </box>

      {/* ── Power buttons ── */}
      <PowerButtons />

    </box>
  )
}
