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
  readonly property var gpus: snapshot && snapshot.gpus ? snapshot.gpus : []

  function memoryPercent(gpu) {
    return gpu && Number(gpu.memoryTotalBytes) > 0
      ? 100 * Number(gpu.memoryUsedBytes || 0) / Number(gpu.memoryTotalBytes) : 0
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

    Repeater {
      model: root.gpus
      delegate: SurfaceCard {
        required property var modelData
        width: parent.width
        title: modelData.vendor || "GPU"
        subtitle: modelData.name || "Unknown graphics adapter"
        icon: "󰢮"
        foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
        elevated: true

        Row {
          width: parent.width
          spacing: Style.spacing.xxl

          RingGauge {
            width: Style.space(112)
            height: width
            value: Number(modelData.usagePercent || 0)
            valueText: Model.percent(modelData.usagePercent)
            label: "GPU"
            foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
          }

          Column {
            width: parent.width - parent.children[0].width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.xl

            MetricBar {
              width: parent.width
              label: "Video memory"
              valueText: Number(modelData.memoryTotalBytes) > 0 ? Model.percent(root.memoryPercent(modelData), 1) : "—"
              detailText: Number(modelData.memoryTotalBytes) > 0
                ? Model.bytes(modelData.memoryUsedBytes, false) + " / " + Model.bytes(modelData.memoryTotalBytes, false)
                : "Dedicated memory data unavailable"
              progress: root.memoryPercent(modelData)
              foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
            }

            Row {
              width: parent.width
              spacing: Style.spacing.xl
              MetricTile { width: (parent.width - parent.spacing * 2) / 3; icon: "󰈸"; label: "Temp"; value: Model.temperature(modelData.temperatureC); foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily }
              MetricTile { width: (parent.width - parent.spacing * 2) / 3; icon: "󰓅"; label: "Clock"; value: Model.frequency(modelData.frequencyMHz); foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily }
              MetricTile { width: (parent.width - parent.spacing * 2) / 3; icon: "󰚥"; label: "Power"; value: modelData.powerWatts === null || modelData.powerWatts === undefined ? "—" : Number(modelData.powerWatts).toFixed(1) + " W"; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily }
            }
          }
        }
      }
    }

    EmptyState {
      visible: root.gpus.length === 0
      width: parent.width
      topPadding: Style.space(52)
      icon: "󰢮"
      title: "GPU data unavailable"
      detail: "Your graphics driver did not expose readable metrics. The rest of Omarchy Stats remains available."
      foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
    }
  }
}
