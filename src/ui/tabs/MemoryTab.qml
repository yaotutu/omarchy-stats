import QtQuick
import QtQuick.Controls
import qs.Commons
import "../components"
import "../Model.js" as Model

Flickable {
  id: root
  property var snapshot: null
  property var history: []
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  readonly property var memory: snapshot && snapshot.memory ? snapshot.memory : null
  readonly property real swapPercent: memory && Number(memory.swapTotalBytes) > 0
    ? 100 * Number(memory.swapUsedBytes || 0) / Number(memory.swapTotalBytes) : 0

  clip: true
  contentWidth: width
  contentHeight: content.implicitHeight
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

  Column {
    id: content
    width: root.width
    spacing: Style.spacing.xxl

    SurfaceCard {
      width: parent.width
      height: Style.space(176)
      foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
      elevated: true

      Row {
        width: parent.width
        height: Style.space(138)
        spacing: Style.spacing.xxl

        RingGauge {
          width: Style.space(126)
          height: width
          anchors.verticalCenter: parent.verticalCenter
          value: root.memory ? Number(root.memory.usagePercent || 0) : 0
          valueText: root.memory ? Model.percent(root.memory.usagePercent) : "—"
          label: "Memory"
          foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
        }

        Column {
          width: parent.width - parent.children[0].width - parent.spacing
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.spacing.md

          Text {
            width: parent.width
            text: root.memory
              ? Model.bytes(root.memory.usedBytes, false) + " used of " + Model.bytes(root.memory.totalBytes, false)
              : "Memory data unavailable"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            elide: Text.ElideRight
          }
          Text {
            width: parent.width
            text: root.memory ? Model.bytes(root.memory.availableBytes, false) + " immediately available" : ""
            color: Color.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }
          Sparkline {
            width: parent.width
            height: Style.space(72)
            samples: root.history
            lineColor: root.accent
            ceiling: 100
          }
        }
      }
    }

    Grid {
      width: parent.width
      columns: 3
      spacing: Style.spacing.xl

      MetricTile { width: (root.width - Style.spacing.xl * 2) / 3; icon: "󰆼"; label: "Used"; value: root.memory ? Model.bytes(root.memory.usedBytes, false) : "—"; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily; highlighted: true }
      MetricTile { width: (root.width - Style.spacing.xl * 2) / 3; icon: "󰅖"; label: "Available"; value: root.memory ? Model.bytes(root.memory.availableBytes, false) : "—"; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily }
      MetricTile { width: (root.width - Style.spacing.xl * 2) / 3; icon: "󰪺"; label: "Cache"; value: root.memory ? Model.bytes(root.memory.cachedBytes, false) : "—"; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily }
      MetricTile { width: (root.width - Style.spacing.xl * 2) / 3; icon: "󰋊"; label: "Free"; value: root.memory ? Model.bytes(root.memory.freeBytes, false) : "—"; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily }
      MetricTile { width: (root.width - Style.spacing.xl * 2) / 3; icon: "󰒍"; label: "Shared"; value: root.memory ? Model.bytes(root.memory.sharedBytes, false) : "—"; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily }
      MetricTile { width: (root.width - Style.spacing.xl * 2) / 3; icon: "󰘚"; label: "Buffers"; value: root.memory ? Model.bytes(root.memory.bufferBytes, false) : "—"; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily }
    }

    SurfaceCard {
      width: parent.width
      title: "Swap"
      subtitle: root.memory ? Model.bytes(root.memory.swapUsedBytes, false) + " used of " + Model.bytes(root.memory.swapTotalBytes, false) : "Unavailable"
      icon: "󰯍"
      foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
      MetricBar {
        width: parent.width
        label: "Swap utilization"
        valueText: Model.percent(root.swapPercent, 1)
        progress: root.swapPercent
        foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
      }
    }
  }
}
