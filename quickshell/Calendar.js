.pragma library

// ── Names ───────────────────────────────────────────────────────────────
var monthsG = ["January","February","March","April","May","June","July",
               "August","September","October","November","December"]
var weekdaysLong  = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
var weekdaysShort = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
// Islamic-civil month names
var hijriMonths = ["Muharram","Safar","Rabi al-Awwal","Rabi al-Thani",
                   "Jumada al-Awwal","Jumada al-Thani","Rajab","Shaban",
                   "Ramadan","Shawwal","Dhu al-Qadah","Dhu al-Hijjah"]

function _t(x) { return Math.trunc(x) }

// ── Calendar conversions (tabular Islamic-civil / Kuwaiti algorithm) ─────
// Gregorian (y, m 1-12, d) -> Julian Day Number
function g2jd(y, m, d) {
    var a = _t((14 - m) / 12)
    var yy = y + 4800 - a
    var mm = m + 12 * a - 3
    return d + _t((153 * mm + 2) / 5) + 365 * yy
             + _t(yy / 4) - _t(yy / 100) + _t(yy / 400) - 32045
}

// Julian Day Number -> Gregorian {y, m, d}
function jd2g(jd) {
    var a = jd + 32044
    var b = _t((4 * a + 3) / 146097)
    var c = a - _t(146097 * b / 4)
    var dd = _t((4 * c + 3) / 1461)
    var e = c - _t(1461 * dd / 4)
    var m = _t((5 * e + 2) / 153)
    var day = e - _t((153 * m + 2) / 5) + 1
    var month = m + 3 - 12 * _t(m / 10)
    var year = 100 * b + dd - 4800 + _t(m / 10)
    return { y: year, m: month, d: day }
}

// Julian Day Number -> Islamic-civil {y, m, d}
function jd2islamic(jd) {
    var l = jd - 1948440 + 10632
    var n = _t((l - 1) / 10631)
    l = l - 10631 * n + 354
    var j = _t((10985 - l) / 5316) * _t((50 * l) / 17719)
          + _t(l / 5670) * _t((43 * l) / 15238)
    l = l - _t((30 - j) / 15) * _t((17719 * j) / 50)
          - _t(j / 16) * _t((15238 * j) / 43) + 29
    var m = _t((24 * l) / 709)
    var d = l - _t((709 * m) / 24)
    var y = 30 * n + j - 30
    return { y: y, m: m, d: d }
}

// Islamic-civil (y, m 1-12, d) -> Julian Day Number
function islamic2jd(y, m, d) {
    return _t((11 * y + 3) / 30) + 354 * y + 30 * m
         - _t((m - 1) / 2) + d + 1948440 - 385
}

function dateToHijri(dt) {
    return jd2islamic(g2jd(dt.getFullYear(), dt.getMonth() + 1, dt.getDate()))
}
function hijriToDate(y, m, d) {
    var g = jd2g(islamic2jd(y, m, d))
    return new Date(g.y, g.m - 1, g.d)
}
function firstGregOfHijriMonth(dt) {
    var h = dateToHijri(dt)
    return hijriToDate(h.y, h.m, 1)
}
// Move to the first Gregorian day of the prev/next Hijri month
function navHijri(dt, dir) {
    var h = dateToHijri(dt)
    var y = h.y, m = h.m + dir
    if (m < 1) { m = 12; y-- }
    if (m > 12) { m = 1; y++ }
    return hijriToDate(y, m, 1)
}

// ── Helpers ──────────────────────────────────────────────────────────────
function key(dt) { return dt.getFullYear() + "-" + dt.getMonth() + "-" + dt.getDate() }
function dateFromKey(k) { var p = k.split("-"); return new Date(+p[0], +p[1], +p[2]) }
function addDays(dt, n) { return new Date(dt.getFullYear(), dt.getMonth(), dt.getDate() + n) }
function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear()
        && a.getMonth() === b.getMonth()
        && a.getDate() === b.getDate()
}

function weekdayHeaders(monStart) {
    return monStart ? ["Mo","Tu","We","Th","Fr","Sa","Su"]
                    : ["Su","Mo","Tu","We","Th","Fr","Sa"]
}

// Returns 42 cells: {num, inMonth, key, isToday, isSel}
function buildGrid(now, viewY, viewM, hijriRef, hijri, monStart, selectedKey) {
    var gs, aM, aY
    if (hijri) {
        var fg = firstGregOfHijriMonth(hijriRef)
        var hh = dateToHijri(hijriRef); aM = hh.m; aY = hh.y
        var off = fg.getDay(); if (monStart) off = (off + 6) % 7
        gs = addDays(fg, -off)
    } else {
        var first = new Date(viewY, viewM, 1)
        var off2 = first.getDay(); if (monStart) off2 = (off2 + 6) % 7
        gs = new Date(viewY, viewM, 1 - off2)
    }
    var cells = []
    for (var i = 0; i < 42; i++) {
        var d = addDays(gs, i)
        var inMonth, num
        if (hijri) {
            var cp = dateToHijri(d); num = cp.d
            inMonth = (cp.m === aM && cp.y === aY)
        } else {
            inMonth = (d.getMonth() === viewM && d.getFullYear() === viewY)
            num = d.getDate()
        }
        var k = key(d)
        cells.push({ num: num, inMonth: inMonth, key: k,
                     isToday: sameDay(d, now), isSel: (selectedKey === k) })
    }
    return cells
}

function monthLabel(viewY, viewM, hijriRef, hijri) {
    if (hijri) {
        var h = dateToHijri(hijriRef)
        return hijriMonths[h.m - 1] + " " + h.y + " AH"
    }
    return monthsG[viewM] + " " + viewY
}

function formatFull(dt, hijri) {
    var wd = weekdaysLong[dt.getDay()]
    if (hijri) {
        var h = dateToHijri(dt)
        return wd + ", " + hijriMonths[h.m - 1] + " " + h.d + ", " + h.y + " AH"
    }
    return wd + ", " + monthsG[dt.getMonth()] + " " + dt.getDate() + ", " + dt.getFullYear()
}

// ── Days-left logic (Gregorian-based, date-only) ─────────────────────────
function relative(now, sel) {
    var a = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    var b = new Date(sel.getFullYear(), sel.getMonth(), sel.getDate())
    var days = Math.round((b - a) / 86400000)
    if (days === 0) return "Today"
    var fut = days > 0, ad = Math.abs(days)
    if (ad === 1) return fut ? "Tomorrow" : "Yesterday"
    var start = fut ? a : b, end = fut ? b : a
    var m = 0, probe = new Date(start)
    while (true) {
        var nx = new Date(probe); nx.setMonth(nx.getMonth() + 1)
        if (nx <= end) { m++; probe = nx } else break
    }
    var rem = Math.round((end - probe) / 86400000)
    var dir = fut ? " left" : " ago"
    if (m === 0) return ad + " days" + dir
    var s = m + (m === 1 ? " month" : " months")
    if (rem > 0) s += " " + rem + (rem === 1 ? " day" : " days")
    return s + dir
}

// ── World clocks (offset-based, in minutes east of UTC) ──────────────────
function _p2(n) { return n < 10 ? "0" + n : "" + n }

function fmtClock(now, offsetMin, h12, showSec) {
    var t = new Date(now.getTime() + offsetMin * 60000)
    var H = t.getUTCHours(), M = t.getUTCMinutes(), S = t.getUTCSeconds()
    var ampm = ""
    if (h12) { ampm = H >= 12 ? " PM" : " AM"; H = H % 12 || 12 }
    var s = _p2(H) + ":" + _p2(M)
    if (showSec) s += ":" + _p2(S)
    return s + ampm
}

function clockWeekday(now, offsetMin) {
    var t = new Date(now.getTime() + offsetMin * 60000)
    return weekdaysShort[t.getUTCDay()]
}

// Parse a "+HHMM" / "-HHMM" offset (from `date +%z`) into minutes east of UTC
function parseOffset(z) {
    if (!z || z.length < 5) return 0
    var sign = z[0] === "-" ? -1 : 1
    var hh = parseInt(z.slice(1, 3), 10)
    var mm = parseInt(z.slice(3, 5), 10)
    return sign * (hh * 60 + mm)
}
