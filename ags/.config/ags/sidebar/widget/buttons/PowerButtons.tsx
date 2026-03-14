import Gtk from "gi://Gtk?version=4.0"
import Gio from "gi://Gio"

function exec(argv: string[]) {
  try {
    Gio.Subprocess.new(argv, Gio.SubprocessFlags.NONE)
  } catch (e) {
    console.error("exec failed:", e)
  }
}

const ACTIONS = [
  { icon: "󰍃", label: "Logout",   cssClass: "btn-logout",   argv: ["hyprctl", "dispatch", "exit"] },
  { icon: "󰌾", label: "Lock",     cssClass: "btn-lock",     argv: ["hyprlock"] },
  { icon: "󰑓", label: "Restart",  cssClass: "btn-restart",  argv: ["systemctl", "reboot"] },
  { icon: "󰐥", label: "Shutdown", cssClass: "btn-shutdown", argv: ["systemctl", "poweroff"] },
] as const

export default function PowerButtons() {
  return (
    <box cssClasses={["power-row"]} spacing={8} homogeneous={true}>
      {ACTIONS.map(({ icon, label, cssClass, argv }) => (
        <button
          cssClasses={["power-btn", cssClass]}
          tooltipText={label}
          onClicked={() => exec(argv)}
        >
          <label label={icon} cssClasses={["power-icon"]} />
        </button>
      ))}
    </box>
  )
}
