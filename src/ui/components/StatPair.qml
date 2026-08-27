import QtQuick
import qs.Commons

Item {
  id: root
  property string label: ""
  property string value: "—"
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property bool emphasize: false
  implicitHeight: Math.max(left.implicitHeight, right.implicitHeight)

  Text {
    id: left
    anchors.left: parent.left
    anchors.right: right.left
    anchors.rightMargin: Style.spacing.xl
    text: root.label
    color: Color.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideRight
  }
  Text {
    id: right
    anchors.right: parent.right
    text: root.value
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: root.emphasize ? Style.font.body : Style.font.bodySmall
    font.bold: root.emphasize
  }
}
