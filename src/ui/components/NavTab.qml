import QtQuick
import qs.Commons

Item {
  id: root

  property string icon: ""
  property string label: ""
  property bool selected: false
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  signal clicked()

  implicitHeight: Style.space(40)

  Row {
    anchors.centerIn: parent
    spacing: Style.spacing.md

    Text {
      text: root.icon
      color: root.selected ? root.foreground : Color.muted
      opacity: root.selected ? 1.0 : 0.62
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.label
      color: root.selected ? root.foreground : Color.muted
      opacity: root.selected ? 1.0 : 0.62
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: root.selected
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.clicked()
  }
}
