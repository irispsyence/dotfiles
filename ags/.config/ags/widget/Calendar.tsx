import { createEffect } from "gnim"
import Gtk from "gi://Gtk?version=4.0"
import { buildCalendarGrid, isToday, MONTHS, YEARS } from "./calendarLogic"
import { month, setMonth, year, setYear, prev, next } from "./calendarState"

export default function Calendar() {

  return (
    <box cssClasses={["calendar"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}>

      {/* ── Header: dropdowns + nav ── */}
      <box cssClasses={["calendar-header"]} spacing={8}>
        <box spacing={4} hexpand={true}>
          {/* Month dropdown */}
          <box $={(self) => {
            const combo = new Gtk.DropDown({ model: Gtk.StringList.new(MONTHS) })
            createEffect(() => combo.set_selected(month()))
            combo.connect("notify::selected", () => setMonth(combo.selected))
            self.append(combo)
          }} />
          {/* Year dropdown */}
          <box $={(self) => {
            const combo = new Gtk.DropDown({ model: Gtk.StringList.new(YEARS.map(String)) })
            createEffect(() => combo.set_selected(YEARS.indexOf(year())))
            combo.connect("notify::selected", () => setYear(YEARS[combo.selected]))
            self.append(combo)
          }} />
        </box>
        <box spacing={2}>
          <button cssClasses={["calendar-nav"]} onClicked={prev}>
            <label label="‹" />
          </button>
          <button cssClasses={["calendar-nav"]} onClicked={next}>
            <label label="›" />
          </button>
        </box>
      </box>

      {/* ── Day-of-week labels ── */}
      <box cssClasses={["calendar-day-labels"]} homogeneous={true}>
        {["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map(d => (
          <label cssClasses={["calendar-day-label"]} label={d} />
        ))}
      </box>

      {/* ── Grid ── */}
      <box
        cssClasses={["calendar-grid"]}
        orientation={Gtk.Orientation.VERTICAL}
        spacing={2}
        $={(gridBox) => {
          createEffect(() => {
            // Clear previous rows
            let child = gridBox.get_first_child()
            while (child) {
              const next = child.get_next_sibling()
              gridBox.remove(child)
              child = next
            }

            // Build new rows
            buildCalendarGrid(month(), year()).forEach(row => {
              const rowBox = new Gtk.Box({ homogeneous: true, spacing: 2 })
              row.forEach(day => {
                // Wrap each cell in a box so background-color renders reliably
                const cellBox = new Gtk.Box({ halign: Gtk.Align.CENTER, valign: Gtk.Align.CENTER })
                const label = new Gtk.Label({ label: day === null ? "" : String(day) })
                cellBox.add_css_class("calendar-cell")
                if (day === null) {
                  cellBox.add_css_class("calendar-cell-empty")
                } else if (isToday(day, month(), year())) {
                  cellBox.add_css_class("calendar-cell-today")
                  label.add_css_class("calendar-cell-today-label")
                }
                cellBox.append(label)
                rowBox.append(cellBox)
              })
              gridBox.append(rowBox)
            })
          })
        }}
      />

    </box>
  )
}
