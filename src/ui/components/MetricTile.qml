import QtQuick
import qs.Commons

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property string value: "—"
  property string detail: ""
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property bool highlighted: false

  readonly property color dim: Color.muted

  radius: Math.max(Style.cornerRadius, Style.space(8))
  color: highlighted
    ? Qt.rgba(accent.r, accent.g, accent.b, 0.12)
    : Qt.rgba(foreground.r, foreground.g, foreground.b, 0.035)
  border.width: Style.spacing.hairline
  border.color: highlighted
    ? Qt.rgba(accent.r, accent.g, accent.b, 0.22)
    : Qt.rgba(foreground.r, foreground.g, foreground.b, 0.065)
  implicitHeight: Style.space(78)

  Row {
    anchors.fill: parent
    anchors.margins: Style.spacing.xxl
    spacing: Style.spacing.lg

    Rectangle {
      visible: root.icon !== ""
      width: Style.space(34)
      height: width
      anchors.verticalCenter: parent.verticalCenter
      radius: Math.max(Style.cornerRadius, Style.space(8))
      color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)

      Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
      }
    }

    Column {
      width: parent.width - (root.icon !== "" ? parent.children[0].width + parent.spacing : 0)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.spacing.xxs

      Text {
        width: parent.width
        text: root.label.toUpperCase()
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 0.7
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        text: root.value
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        visible: root.detail !== ""
        width: parent.width
        text: root.detail
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }
  }
}
