export function getDaysInMonth(month: number, year: number): number {
  return new Date(year, month + 1, 0).getDate()
}

export function getFirstDayOffset(month: number, year: number): number {
  return new Date(year, month, 1).getDay()
}

export function buildCalendarGrid(month: number, year: number): (number | null)[][] {
  const days = getDaysInMonth(month, year)
  const offset = getFirstDayOffset(month, year)

  const cells: (number | null)[] = []
  for (let i = 0; i < offset; i++) cells.push(null)
  for (let d = 1; d <= days; d++) cells.push(d)
  while (cells.length < 42) cells.push(null)

  const grid: (number | null)[][] = []
  for (let row = 0; row < 6; row++) {
    grid.push(cells.slice(row * 7, row * 7 + 7))
  }
  return grid
}

export function isToday(day: number, month: number, year: number): boolean {
  const now = new Date()
  return (
    day === now.getDate() &&
    month === now.getMonth() &&
    year === now.getFullYear()
  )
}

export const MONTHS = [
  "January", "February", "March", "April",
  "May", "June", "July", "August",
  "September", "October", "November", "December",
]

export const YEARS = Array.from({ length: 31 }, (_, i) => 2020 + i) // 2020–2050
