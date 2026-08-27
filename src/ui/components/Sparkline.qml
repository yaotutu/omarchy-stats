import QtQuick
import qs.Commons

Canvas {
  id: root
  property var samples: []
  property var secondarySamples: []
  property real ceiling: 100
  property color lineColor: Color.accent
  property color secondaryLineColor: Qt.lighter(Color.accent, 1.35)
  property color fillColor: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.12)
  property bool showGrid: true
  implicitHeight: Style.space(104)
  antialiasing: true

  function repaint() { requestPaint() }
  onSamplesChanged: repaint()
  onSecondarySamplesChanged: repaint()
  onWidthChanged: repaint()
  onHeightChanged: repaint()
  onLineColorChanged: repaint()
  onSecondaryLineColorChanged: repaint()
  onCeilingChanged: repaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    if (width <= 0 || height <= 0) return

    var inset = 2
    var usableHeight = height - inset * 2
    if (root.showGrid) {
      ctx.lineWidth = 1
      ctx.strokeStyle = Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.055)
      for (var g = 1; g < 4; g++) {
        var gy = Math.round(height * g / 4) + 0.5
        ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke()
      }
    }

    function points(values) {
      var result = []
      if (!values || values.length < 2) return result
      var step = width / Math.max(1, values.length - 1)
      for (var i = 0; i < values.length; i++) {
        var value = Math.max(0, Math.min(root.ceiling, Number(values[i] || 0)))
        result.push({ x: i * step, y: height - inset - value / Math.max(1, root.ceiling) * usableHeight })
      }
      return result
    }

    function draw(values, color, fill) {
      var pts = points(values)
      if (pts.length < 2) return
      if (fill) {
        ctx.beginPath(); ctx.moveTo(pts[0].x, height); ctx.lineTo(pts[0].x, pts[0].y)
        for (var i = 1; i < pts.length; i++) ctx.lineTo(pts[i].x, pts[i].y)
        ctx.lineTo(width, height); ctx.closePath(); ctx.fillStyle = root.fillColor; ctx.fill()
      }
      ctx.beginPath(); ctx.moveTo(pts[0].x, pts[0].y)
      for (var j = 1; j < pts.length; j++) ctx.lineTo(pts[j].x, pts[j].y)
      ctx.strokeStyle = color; ctx.lineWidth = 2; ctx.lineJoin = "round"; ctx.lineCap = "round"; ctx.stroke()
    }

    draw(root.samples, root.lineColor, true)
    draw(root.secondarySamples, root.secondaryLineColor, false)
  }
}
