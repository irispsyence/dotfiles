import { createState } from "gnim"

const today = new Date()
export const [month, setMonth] = createState(today.getMonth())
export const [year, setYear] = createState(today.getFullYear())

export function prev() {
  if (month() === 0) { setMonth(11); setYear(year() - 1) }
  else setMonth(month() - 1)
}

export function next() {
  if (month() === 11) { setMonth(0); setYear(year() + 1) }
  else setMonth(month() + 1)
}
