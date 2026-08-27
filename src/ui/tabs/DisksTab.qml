import QtQuick
import QtQuick.Controls
import qs.Commons
import "../components"
import "../Model.js" as Model

Flickable {
  id: root
  property var snapshot: null
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  readonly property var disks: snapshot && snapshot.storage ? snapshot.storage : []

  clip: true
  contentWidth: width
  contentHeight: content.implicitHeight
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

  Column {
    id: content
    width: root.width
    spacing: Style.spacing.xxl

    Repeater {
      model: root.disks
      delegate: SurfaceCard {
        required property var modelData
        width: parent.width
        title: modelData.mountPoint === "/" ? "System volume" : modelData.mountPoint
        subtitle: modelData.source + "  ·  " + String(modelData.fileSystem || "").toUpperCase()
        icon: modelData.mountPoint === "/" ? "󰋊" : "󰆼"
        foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
        elevated: modelData.mountPoint === "/"

        Row {
          width: parent.width
          spacing: Style.spacing.xxl

          RingGauge {
            width: Style.space(108)
            height: width
            value: Number(modelData.usagePercent || 0)
            valueText: Model.percent(modelData.usagePercent)
            label: "Used"
            foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
          }

          Column {
            width: parent.width - parent.children[0].width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.xl

            MetricBar {
              width: parent.width
              label: "Capacity"
              valueText: Model.bytes(modelData.totalBytes, false)
              detailText: Model.bytes(modelData.usedBytes, false) + " used  ·  " + Model.bytes(modelData.freeBytes, false) + " available"
              progress: Number(modelData.usagePercent || 0)
              foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
            }

            Row {
              width: parent.width
              spacing: Style.spacing.xl
              MetricTile {
                width: (parent.width - parent.spacing) / 2
                icon: "󰕒"
                label: "Read"
                value: Model.bytes(modelData.readBytesPerSecond, true)
                foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
              }
              MetricTile {
                width: (parent.width - parent.spacing) / 2
                icon: "󰇚"
                label: "Write"
                value: Model.bytes(modelData.writeBytesPerSecond, true)
                foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
              }
            }
          }
        }

        Text {
          visible: (modelData.additionalMounts || []).length > 0
          width: parent.width
          text: "Also mounted at " + (modelData.additionalMounts || []).join(", ")
          color: Color.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }

    EmptyState {
      visible: root.disks.length === 0
      width: parent.width
      topPadding: Style.space(52)
      icon: "󰋊"
      title: "Storage unavailable"
      detail: "No readable mounted filesystem was found."
      foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
    }
  }
}
