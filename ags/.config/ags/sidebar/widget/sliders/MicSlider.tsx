import Gtk from "gi://Gtk?version=4.0"
import Wp from "gi://AstalWp"

// Requires: paru -S astal-wireplumber

export default function MicSlider() {
  const wp = Wp.get_default()
  const mic = wp?.audio?.defaultMicrophone

  return (
    <box cssClasses={["slider-row"]} spacing={10}>

      {/* Mute toggle button */}
      <box $={(self) => {
        const btn = new Gtk.Button()
        btn.add_css_class("slider-icon-btn")
        const lbl = new Gtk.Label({ label: "󰍬" })
        lbl.add_css_class("slider-icon")
        btn.set_child(lbl)

        if (mic) {
          const updateMute = () => {
            lbl.label = mic.mute ? "󰍭" : "󰍬"
            mic.mute ? btn.add_css_class("muted") : btn.remove_css_class("muted")
          }
          updateMute()
          mic.connect("notify::mute", updateMute)
          btn.connect("clicked", () => { mic.mute = !mic.mute })
        }

        self.append(btn)
      }} />

      {/* Mic volume slider */}
      <box hexpand={true} $={(self) => {
        const scale = new Gtk.Scale({
          orientation: Gtk.Orientation.HORIZONTAL,
          hexpand: true,
          drawValue: false,
        })
        scale.set_range(0, 1)
        scale.add_css_class("mic-slider")

        if (mic) {
          scale.set_value(mic.volume)
          let fromService = false
          mic.connect("notify::volume", () => {
            fromService = true
            scale.set_value(mic.volume)
            fromService = false
          })
          scale.connect("value-changed", () => {
            if (!fromService) mic.volume = scale.get_value()
          })
        }

        self.append(scale)
      }} />

    </box>
  )
}
