.pragma library

function finite(value) {
  if (value === null || value === undefined || value === "") return null
  var number = Number(value)
  return isFinite(number) ? number : null
}

function percent(value, digits) {
  var number = finite(value)
  if (number === null) return "—"
  return number.toFixed(digits === undefined ? 0 : digits) + "%"
}

function bytes(value, rate) {
  var number = finite(value)
  if (number === null || number < 0) return "—"
  var labels = ["B", "KiB", "MiB", "GiB", "TiB"]
  var unit = 0
  while (number >= 1024 && unit < labels.length - 1) {
    number /= 1024
    unit += 1
  }
  var digits = number >= 100 || unit === 0 ? 0 : (number >= 10 ? 1 : 2)
  return number.toFixed(digits) + " " + labels[unit] + (rate ? "/s" : "")
}

function compactRate(value) {
  var number = finite(value)
  if (number === null || number < 0) return "—"
  var labels = ["B", "K", "M", "G", "T"]
  var unit = 0
  while (number >= 1024 && unit < labels.length - 1) {
    number /= 1024
    unit += 1
  }
  var digits = number >= 10 || unit === 0 ? 0 : 1
  return number.toFixed(digits) + labels[unit] + "/s"
}

function frequency(mhz) {
  var number = finite(mhz)
  if (number === null) return "—"
  return number >= 1000 ? (number / 1000).toFixed(2) + " GHz" : number.toFixed(0) + " MHz"
}

function temperature(celsius) {
  var number = finite(celsius)
  return number === null ? "—" : number.toFixed(0) + "°C"
}

function duration(seconds) {
  var value = finite(seconds)
  if (value === null) return "—"
  var days = Math.floor(value / 86400)
  var hours = Math.floor((value % 86400) / 3600)
  var minutes = Math.floor((value % 3600) / 60)
  if (days > 0) return days + "d " + hours + "h"
  if (hours > 0) return hours + "h " + minutes + "m"
  return minutes + "m"
}

function appendHistory(values, next, capacity) {
  var copy = values ? values.slice(0) : []
  var number = finite(next)
  copy.push(number === null ? 0 : number)
  while (copy.length > capacity) copy.shift()
  return copy
}

function processRows(items, query, sortKey, descending) {
  var source = items || []
  var needle = String(query || "").toLowerCase().trim()
  var result = source.filter(function(item) {
    if (!needle) return true
    return String(item.name || "").toLowerCase().indexOf(needle) >= 0
      || String(item.command || "").toLowerCase().indexOf(needle) >= 0
      || String(item.user || "").toLowerCase().indexOf(needle) >= 0
      || String(item.pid) === needle
  })
  var key = sortKey === "memory" ? "residentBytes" : "cpuPercent"
  result.sort(function(a, b) {
    var delta = Number(a[key] || 0) - Number(b[key] || 0)
    if (delta === 0) delta = Number(a.pid || 0) - Number(b.pid || 0)
    return descending ? -delta : delta
  })
  return result
}

function interfaceByName(network, name) {
  var rows = network && network.interfaces ? network.interfaces : []
  for (var i = 0; i < rows.length; i++) if (rows[i].name === name) return rows[i]
  for (var j = 0; j < rows.length; j++) if (rows[j].active) return rows[j]
  return rows.length ? rows[0] : null
}
