import QtQuick
import qs.Commons

Rectangle {
  id: root
  property string text: ""
  property string icon: ""
  property bool selected: false
  property bool destructive: false
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  signal clicked()

  readonly property color tone: destructive ? Color.urgent : accent

  implicitWidth: content.implicitWidth + Style.spacing.controlPaddingX * 2
  implicitHeight: Math.max(Style.spacing.controlHeight, content.implicitHeight + Style.spacing.controlPaddingY * 2)
  radius: Math.max(Style.cornerRadius, Style.space(7))
  color: mouse.containsMouse
    ? Qt.rgba(tone.r, tone.g, tone.b, 0.16)
    : (selected ? Qt.rgba(tone.r, tone.g, tone.b, 0.12) : Qt.rgba(foreground.r, foreground.g, foreground.b, 0.035))
  border.width: Style.spacing.hairline
  border.color: selected || destructive
    ? Qt.rgba(tone.r, tone.g, tone.b, 0.28)
    : Qt.rgba(foreground.r, foreground.g, foreground.b, 0.075)

  Behavior on color { ColorAnimation { duration: 100 } }

  Row {
    id: content
    anchors.centerIn: parent
    spacing: Style.spacing.sm

    Text {
      visible: root.icon !== ""
      text: root.icon
      color: root.destructive ? Color.urgent : (root.selected ? root.accent : root.foreground)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.text
      color: root.destructive ? Color.urgent : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: root.selected || root.destructive
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
