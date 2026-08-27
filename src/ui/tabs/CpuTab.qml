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

  readonly property var cpu: snapshot && snapshot.cpu ? snapshot.cpu : null
  readonly property var cores: cpu ? (cpu.cores || []) : []
  readonly property var fans: cpu ? (cpu.fans || []) : []

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
      foreground: root.foreground
      accent: root.accent
      fontFamily: root.fontFamily
      elevated: true

      Row {
        width: parent.width
        height: Style.space(138)
        spacing: Style.spacing.xxl

        RingGauge {
          width: Style.space(126)
          height: width
          anchors.verticalCenter: parent.verticalCenter
          value: root.cpu ? Number(root.cpu.usagePercent || 0) : 0
          valueText: root.cpu ? Model.percent(root.cpu.usagePercent) : "—"
          label: "CPU"
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
        }

        Column {
          width: parent.width - parent.children[0].width - parent.spacing
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.spacing.md

          Text {
            width: parent.width
            text: root.cpu ? root.cpu.model : "Processor unavailable"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
          }

          Row {
            width: parent.width
            spacing: Style.spacing.xxl
            StatPair {
              width: (parent.width - parent.spacing) / 2
              label: "Frequency"
              value: root.cpu ? Model.frequency(root.cpu.averageFrequencyMHz) : "—"
              foreground: root.foreground
              fontFamily: root.fontFamily
              emphasize: true
            }
            StatPair {
              width: (parent.width - parent.spacing) / 2
              label: "Temperature"
              value: root.cpu ? Model.temperature(root.cpu.temperatureC) : "—"
              foreground: root.foreground
              fontFamily: root.fontFamily
              emphasize: true
            }
          }

          Sparkline {
            width: parent.width
            height: Style.space(62)
            samples: root.history
            lineColor: root.accent
            ceiling: 100
          }
        }
      }
    }

    Row {
      width: parent.width
      spacing: Style.spacing.xl
      MetricTile {
        width: (parent.width - parent.spacing * 2) / 3
        icon: "󰓅"
        label: "Logical cores"
        value: String(root.cores.length || "—")
        detail: "live per-core load"
        foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
      }
      MetricTile {
        width: (parent.width - parent.spacing * 2) / 3
        icon: "󰈐"
        label: "Load average"
        value: root.snapshot && root.snapshot.loadAverage ? Number(root.snapshot.loadAverage[0] || 0).toFixed(2) : "—"
        detail: "1 minute"
        foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
      }
      MetricTile {
        width: (parent.width - parent.spacing * 2) / 3
        icon: "󰈸"
        label: "Fan"
        value: root.fans.length ? String(root.fans[0].rpm) : "—"
        detail: root.fans.length ? "RPM" : "not exposed"
        foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
      }
    }

    Text {
      text: "PER-CORE ACTIVITY"
      color: Color.muted
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      font.letterSpacing: 0.9
    }

    Grid {
      width: parent.width
      columns: 3
      spacing: Style.spacing.xl

      Repeater {
        model: root.cores
        delegate: SurfaceCard {
          required property var modelData
          width: (root.width - Style.spacing.xl * 2) / 3
          padding: Style.spacing.xl
          contentSpacing: Style.spacing.md
          foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily

          Row {
            width: parent.width
            Text {
              width: parent.width - usage.implicitWidth
              text: "Core " + modelData.index
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
            Text {
              id: usage
              text: Model.percent(modelData.usagePercent)
              color: root.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
          }
          MetricBar {
            width: parent.width
            compact: true
            progress: Number(modelData.usagePercent || 0)
            label: Model.frequency(modelData.frequencyMHz)
            valueText: Model.temperature(modelData.temperatureC)
            foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
          }
        }
      }
    }

    SurfaceCard {
      visible: root.fans.length > 0
      width: parent.width
      title: "Cooling"
      subtitle: "Sensors exposed by the system"
      icon: "󰈸"
      foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
      Repeater {
        model: root.fans
        delegate: StatPair {
          required property var modelData
          width: parent.width
          label: modelData.name
          value: String(modelData.rpm) + " RPM"
          foreground: root.foreground; fontFamily: root.fontFamily
        }
      }
    }
  }
}
