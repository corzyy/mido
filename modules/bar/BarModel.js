.pragma library

// Pure layout helpers, ported from Omarchy's BarModel.js. The layout is
// { left: [...], center: [...], right: [...] }, each entry { id, ...settings }.

function isPlainObject(value) {
  return !!value && typeof value === "object" && !Array.isArray(value)
}

function normalizePosition(value) {
  var next = String(value || "").trim()
  return /^(top|bottom|left|right)$/.test(next) ? next : "top"
}

function entrySettings(entry) {
  if (!isPlainObject(entry)) return {}
  var copy = {}
  for (var key in entry) {
    if (key === "id") continue
    copy[key] = entry[key]
  }
  return copy
}

function entryId(entry) {
  if (typeof entry === "string") return entry
  if (isPlainObject(entry)) {
    var id = entry["id"]
    if (id !== undefined && id !== null && String(id) !== "") return String(id)
  }
  return ""
}

function canonicalId(id) {
  return String(id || "").replace(/^omarchy\./, "")
}

function entryIndex(entries, name) {
  if (!Array.isArray(entries)) return -1
  var wanted = canonicalId(name)
  if (wanted === "") return -1
  for (var i = 0; i < entries.length; i++) {
    if (canonicalId(entryId(entries[i])) === wanted) return i
  }
  return -1
}

function entriesBefore(entries, name) {
  var index = entryIndex(entries, name)
  return index <= 0 ? [] : entries.slice(0, index)
}

function entriesAfter(entries, name) {
  var index = entryIndex(entries, name)
  return index === -1 ? [] : entries.slice(index + 1)
}

// The region of `layout` holding the entry `name`, or "".
function findRegion(layout, name) {
  var regions = ["left", "center", "right"]
  for (var i = 0; i < regions.length; i++) {
    var entries = isPlainObject(layout) ? layout[regions[i]] : null
    if (!Array.isArray(entries)) continue
    for (var j = 0; j < entries.length; j++)
      if (entryId(entries[j]) === name) return regions[i]
  }
  return ""
}

// Move the entry `fromName` of region `fromRegion` into `toRegion`, in front of
// the entry `beforeName` (or at the end when that is empty or not found).
// Returns whether the layout changed.
function moveEntry(layout, fromRegion, fromName, toRegion, beforeName) {
  if (!isPlainObject(layout)) return false
  if (!Array.isArray(layout[fromRegion])) layout[fromRegion] = []
  if (!Array.isArray(layout[toRegion])) layout[toRegion] = []
  var fromEntries = layout[fromRegion]
  var toEntries = layout[toRegion]

  var fromIndex = -1
  for (var i = 0; i < fromEntries.length; i++) {
    if (entryId(fromEntries[i]) === fromName) { fromIndex = i; break }
  }
  if (fromIndex < 0) return false

  var toIndex = toEntries.length
  if (beforeName) {
    for (var j = 0; j < toEntries.length; j++) {
      if (entryId(toEntries[j]) === beforeName) { toIndex = j; break }
    }
  }

  if (fromRegion === toRegion && fromIndex === toIndex) return false

  var moved = fromEntries[fromIndex]
  fromEntries.splice(fromIndex, 1)

  if (fromRegion === toRegion && fromIndex < toIndex) toIndex -= 1
  if (toIndex < 0) toIndex = 0
  if (toIndex > toEntries.length) toIndex = toEntries.length
  if (fromRegion === toRegion && fromIndex === toIndex) {
    fromEntries.splice(fromIndex, 0, moved)
    return false
  }

  toEntries.splice(toIndex, 0, moved)
  return true
}

// Resolve a pointer anywhere along the bar to the closest insertion edge.
// Requiring the pointer to sit inside another widget makes the empty space
// around a centered group a dead zone, even though it visually reads as the
// most natural place to drop.
function nearestDropTarget(candidates, point, vertical) {
  var rows = Array.isArray(candidates) ? candidates : []
  var axis = vertical ? Number(point && point.y) : Number(point && point.x)
  if (!isFinite(axis)) return null

  var best = null
  var bestDistance = Infinity
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i]
    if (!row || !row.slot) continue

    var start = Number(vertical ? row.y : row.x)
    var size = Number(vertical ? row.height : row.width)
    if (!isFinite(start) || !isFinite(size) || size <= 0) continue

    var beforeDistance = Math.abs(axis - start)
    var afterDistance = Math.abs(axis - (start + size))
    var after = afterDistance < beforeDistance
    var distance = after ? afterDistance : beforeDistance
    if (distance < bestDistance) {
      best = { slot: row.slot, after: after }
      bestDistance = distance
    }
  }
  return best
}
