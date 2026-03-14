import Gtk from "gi://Gtk?version=4.0"
import Wp from "gi://AstalWp"

// Requires: paru -S astal-wireplumber

export default function VolumeSlider() {
  const wp = Wp.get_default()
  const speaker = wp?.audio?.defaultSpeaker

  return (
    <box cssClasses={["slider-row"]} spacing={10}>

      {/* Mute toggle button */}
      <box $={(self) => {
        const btn = new Gtk.Button()
        btn.add_css_class("slider-icon-btn")
        const lbl = new Gtk.Label({ label: "󰕾" })
        lbl.add_css_class("slider-icon")
        btn.set_child(lbl)

        if (speaker) {
          const updateMute = () => {
            lbl.label = speaker.mute ? "󰝟" : "󰕾"
            speaker.mute ? btn.add_css_class("muted") : btn.remove_css_class("muted")
          }
          updateMute()
          speaker.connect("notify::mute", updateMute)
          btn.connect("clicked", () => { speaker.mute = !speaker.mute })
        }

        self.append(btn)
      }} />

      {/* Volume slider */}
      <box hexpand={true} $={(self) => {
        const scale = new Gtk.Scale({
          orientation: Gtk.Orientation.HORIZONTAL,
          hexpand: true,
          drawValue: false,
        })
        scale.set_range(0, 1)
        scale.add_css_class("volume-slider")

        if (speaker) {
          scale.set_value(speaker.volume)
          let fromService = false
          speaker.connect("notify::volume", () => {
            fromService = true
            scale.set_value(speaker.volume)
            fromService = false
          })
          scale.connect("value-changed", () => {
            if (!fromService) speaker.volume = scale.get_value()
          })
        }

        self.append(scale)
      }} />

    </box>
  )
}
