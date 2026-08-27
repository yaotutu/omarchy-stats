import QtQuick
import qs.Commons

Item {
  id: root
  property string label: ""
  property string valueText: "—"
  property string detailText: ""
  property real progress: 0
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property bool compact: false

  implicitHeight: labels.implicitHeight + Style.spacing.md + Style.space(compact ? 5 : 7)

  Column {
    id: labels
    width: parent.width
    spacing: Style.spacing.xxs

    Row {
      width: parent.width
      spacing: Style.spacing.lg
      Text {
        width: Math.max(0, parent.width - valueLabel.implicitWidth - parent.spacing)
        text: root.label
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: root.compact ? Style.font.caption : Style.font.bodySmall
        font.bold: !root.compact
        elide: Text.ElideRight
      }
      Text {
        id: valueLabel
        text: root.valueText
        color: root.accent
        font.family: root.fontFamily
        font.pixelSize: root.compact ? Style.font.caption : Style.font.bodySmall
        font.bold: true
      }
    }

    Text {
      visible: root.detailText !== ""
      width: parent.width
      text: root.detailText
      color: Color.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: Style.space(root.compact ? 5 : 7)
    radius: height / 2
    color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.085)

    Rectangle {
      width: parent.width * Math.max(0, Math.min(100, root.progress)) / 100
      height: parent.height
      radius: parent.radius
      color: root.accent
      Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }
  }
}
