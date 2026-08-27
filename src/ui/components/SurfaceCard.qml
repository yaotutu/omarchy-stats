import QtQuick
import qs.Commons

Rectangle {
  id: root

  default property alias content: holder.children
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property string title: ""
  property string subtitle: ""
  property string icon: ""
  property real padding: Style.spacing.xxl
  property real contentSpacing: Style.spacing.lg
  property bool elevated: false
  property bool interactive: false

  signal clicked()

  readonly property color dim: Color.muted
  readonly property real resolvedRadius: Math.max(Style.cornerRadius, Style.space(8))

  radius: resolvedRadius
  color: interactive && pointer.containsMouse
    ? Qt.rgba(foreground.r, foreground.g, foreground.b, 0.075)
    : Qt.rgba(foreground.r, foreground.g, foreground.b, elevated ? 0.065 : 0.038)
  border.width: Style.spacing.hairline
  border.color: Qt.rgba(foreground.r, foreground.g, foreground.b, elevated ? 0.13 : 0.075)
  implicitHeight: body.implicitHeight + padding * 2

  Behavior on color { ColorAnimation { duration: 120 } }

  Column {
    id: body
    anchors.fill: parent
    anchors.margins: root.padding
    spacing: root.contentSpacing

    Row {
      id: heading
      visible: root.title !== "" || root.subtitle !== "" || root.icon !== ""
      width: parent.width
      spacing: Style.spacing.lg

      Rectangle {
        visible: root.icon !== ""
        width: Style.space(30)
        height: width
        radius: Math.max(Style.cornerRadius, Style.space(7))
        color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
        anchors.verticalCenter: parent.verticalCenter

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
          visible: root.title !== ""
          text: root.title
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          visible: root.subtitle !== ""
          text: root.subtitle
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }

    Column {
      id: holder
      width: parent.width
      spacing: root.contentSpacing
    }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
