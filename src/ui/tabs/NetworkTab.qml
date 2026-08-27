import QtQuick
import QtQuick.Controls
import qs.Commons
import "../components"
import "../Model.js" as Model

Flickable {
  id: root
  property var snapshot: null
  property var downloadHistory: []
  property var uploadHistory: []
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property string selectedInterface: ""

  readonly property var network: snapshot && snapshot.network ? snapshot.network : null
  readonly property var interfaces: network ? (network.interfaces || []) : []
  readonly property var selected: Model.interfaceByName(network, selectedInterface)
  readonly property real graphCeiling: Math.max(1, peak(downloadHistory), peak(uploadHistory))

  function peak(values) {
    var result = 0
    var list = values || []
    for (var i = 0; i < list.length; i++) result = Math.max(result, Number(list[i] || 0))
    return result
  }

  clip: true
  contentWidth: width
  contentHeight: content.implicitHeight
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

  Column {
    id: content
    width: root.width
    spacing: Style.spacing.xxl

    Row {
      visible: root.interfaces.length > 1
      width: parent.width
      spacing: Style.spacing.md
      Repeater {
        model: root.interfaces
        delegate: ActionChip {
          required property var modelData
          text: modelData.name
          icon: modelData.wireless ? "󰖩" : "󰈀"
          selected: root.selected && root.selected.name === modelData.name
          foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
          onClicked: root.selectedInterface = modelData.name
        }
      }
    }

    SurfaceCard {
      width: parent.width
      height: Style.space(224)
      title: root.selected ? root.selected.name : "Network"
      subtitle: root.selected
        ? ((root.selected.active ? "Active" : "Inactive") + (root.selected.address ? "  ·  " + root.selected.address : ""))
        : "No network interface"
      icon: root.selected && root.selected.wireless ? "󰖩" : "󰈀"
      foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
      elevated: true

      Row {
        width: parent.width
        spacing: Style.spacing.xxl

        Column {
          width: (parent.width - parent.spacing) / 2
          spacing: Style.spacing.xxs
          Text { text: "󰇚  DOWNLOAD"; color: Color.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 0.7 }
          Text { width: parent.width; text: root.selected ? Model.bytes(root.selected.downloadBytesPerSecond, true) : "—"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.display; font.bold: true; elide: Text.ElideRight }
        }
        Column {
          width: (parent.width - parent.spacing) / 2
          spacing: Style.spacing.xxs
          Text { text: "󰕒  UPLOAD"; color: Color.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 0.7 }
          Text { width: parent.width; text: root.selected ? Model.bytes(root.selected.uploadBytesPerSecond, true) : "—"; color: Qt.lighter(root.accent, 1.25); font.family: root.fontFamily; font.pixelSize: Style.font.display; font.bold: true; elide: Text.ElideRight }
        }
      }

      Sparkline {
        width: parent.width
        height: Style.space(86)
        samples: root.downloadHistory
        secondarySamples: root.uploadHistory
        ceiling: root.graphCeiling
        lineColor: root.accent
        secondaryLineColor: Qt.lighter(root.accent, 1.35)
      }
    }

    Row {
      width: parent.width
      spacing: Style.spacing.xl
      MetricTile { width: (parent.width - parent.spacing * 2) / 3; icon: "󰇚"; label: "Received"; value: root.selected ? Model.bytes(root.selected.receivedBytes, false) : "—"; detail: "since boot"; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily }
      MetricTile { width: (parent.width - parent.spacing * 2) / 3; icon: "󰕒"; label: "Sent"; value: root.selected ? Model.bytes(root.selected.sentBytes, false) : "—"; detail: "since boot"; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily }
      MetricTile { width: (parent.width - parent.spacing * 2) / 3; icon: "󰋩"; label: "Link"; value: root.selected ? (root.selected.up ? "Up" : "Down") : "—"; detail: root.selected ? (root.selected.wireless ? "Wireless" : "Wired") : ""; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily; highlighted: root.selected && root.selected.active }
    }

    SurfaceCard {
      visible: root.interfaces.length > 0
      width: parent.width
      title: "Interfaces"
      subtitle: "Available network devices"
      icon: "󰛳"
      foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily

      Repeater {
        model: root.interfaces
        delegate: Item {
          required property var modelData
          width: parent.width
          height: Style.space(32)
          Row {
            anchors.fill: parent
            spacing: Style.spacing.lg
            Text { width: Style.space(24); text: modelData.wireless ? "󰖩" : "󰈀"; color: modelData.active ? root.accent : Color.muted; font.family: root.fontFamily; font.pixelSize: Style.font.body }
            Text { width: Style.space(100); text: modelData.name; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; font.bold: modelData.active; elide: Text.ElideRight }
            Text { width: parent.width - Style.space(224); text: modelData.address || "No address"; color: Color.muted; font.family: root.fontFamily; font.pixelSize: Style.font.caption; elide: Text.ElideRight }
            Text { width: Style.space(100); text: Model.bytes(modelData.downloadBytesPerSecond, true) + " ↓"; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.caption; horizontalAlignment: Text.AlignRight }
          }
        }
      }
    }

    EmptyState {
      visible: root.interfaces.length === 0
      width: parent.width
      topPadding: Style.space(52)
      icon: "󰖪"
      title: "No network data"
      detail: "No readable network interface was found."
      foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
    }
  }
}
