import QtQuick
import qs.Commons

Item {
  id: root

  property real value: 0
  property string valueText: "—"
  property string label: ""
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real ringWidth: Style.spaceReal(7)

  implicitWidth: Style.space(116)
  implicitHeight: implicitWidth

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: true

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var pad = root.ringWidth / 2 + 2
      var cx = width / 2
      var cy = height / 2
      var radius = Math.max(1, Math.min(width, height) / 2 - pad)
      var start = -Math.PI * 0.5
      var bounded = Math.max(0, Math.min(100, Number(root.value || 0)))

      ctx.beginPath()
      ctx.arc(cx, cy, radius, 0, Math.PI * 2, false)
      ctx.strokeStyle = Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.09)
      ctx.lineWidth = root.ringWidth
      ctx.stroke()

      if (bounded > 0) {
        ctx.beginPath()
        ctx.arc(cx, cy, radius, start, start + Math.PI * 2 * bounded / 100, false)
        ctx.strokeStyle = root.accent
        ctx.lineWidth = root.ringWidth
        ctx.lineCap = "round"
        ctx.stroke()
      }
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
  }

  onValueChanged: canvas.requestPaint()
  onForegroundChanged: canvas.requestPaint()
  onAccentChanged: canvas.requestPaint()

  Column {
    anchors.centerIn: parent
    width: parent.width - root.ringWidth * 4
    spacing: Style.spacing.xxs

    Text {
      width: parent.width
      text: root.valueText
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.display
      font.bold: true
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      text: root.label.toUpperCase()
      color: Color.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 0.8
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
    }
  }
}
