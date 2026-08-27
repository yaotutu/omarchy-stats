import QtQuick
import qs.Commons

Column {
  id: root
  property string icon: "󰋼"
  property string title: "Unavailable"
  property string detail: "This system did not provide data for this section."
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real topPadding: 0
  spacing: Style.spacing.lg

  Text {
    width: parent.width
    topPadding: root.topPadding
    text: root.icon
    color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.75)
    font.family: root.fontFamily
    font.pixelSize: Style.font.display
    horizontalAlignment: Text.AlignHCenter
  }
  Text {
    width: parent.width
    text: root.title
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.title
    font.bold: true
    horizontalAlignment: Text.AlignHCenter
  }
  Text {
    width: parent.width
    text: root.detail
    color: Color.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
  }
}
