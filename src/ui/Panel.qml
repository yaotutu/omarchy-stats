import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model
import "components"
import "tabs"

Panel {
  id: root
  moduleName: "omarchy-stats"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: root.bar ? root.bar.barForeground : Color.foreground
  readonly property color accent: Color.accent
  readonly property color dim: Color.muted
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property int detailInterval: Math.max(1, Math.min(10, Number(setting("detailRefreshSeconds", 1)) || 1))
  readonly property string collectorPath: Qt.resolvedUrl("../collector.py").toString().replace(/^file:\/\//, "")

  property var snapshot: null
  property int tabIndex: 0
  property var cpuHistory: []
  property var memoryHistory: []
  property var downloadHistory: []
  property var uploadHistory: []
  property string actionError: ""

  readonly property var tabs: [
    { label: "CPU", icon: "󰻠" },
    { label: "Memory", icon: "" },
    { label: "Disks", icon: "󰋊" },
    { label: "Network", icon: "󰖩" },
    { label: "GPU", icon: "󰢮" },
    { label: "Processes", icon: "󰄉" }
  ]

  function open() { root.controller.show() }
  function openFromHotkey() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.open() }
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function ingest(line) {
    var value = String(line || "").trim()
    if (!value) return
    try {
      var next = JSON.parse(value)
      if (Number(next.schema) !== 1) return
      root.snapshot = next
      root.cpuHistory = Model.appendHistory(root.cpuHistory, next.cpu ? next.cpu.usagePercent : null, 72)
      root.memoryHistory = Model.appendHistory(root.memoryHistory, next.memory ? next.memory.usagePercent : null, 72)
      var selected = Model.interfaceByName(next.network, networkTab.selectedInterface)
      root.downloadHistory = Model.appendHistory(root.downloadHistory, selected ? selected.downloadBytesPerSecond : null, 72)
      root.uploadHistory = Model.appendHistory(root.uploadHistory, selected ? selected.uploadBytesPerSecond : null, 72)
    } catch (error) {
      root.actionError = "Collector returned invalid data"
    }
  }

  function requestSignal(pid, processName, signalName) {
    if (signalProcess.running) return
    root.actionError = ""
    signalProcess.command = ["python3", root.collectorPath, "--signal", String(pid), String(signalName)]
    signalProcess.running = true
  }

  onOpenedChanged: {
    if (opened) Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    else {
      processTab.cancelConfirmation()
      processTab.selectedProcess = null
      root.actionError = ""
    }
  }

  Process {
    id: detailProcess
    running: root.opened
    command: ["python3", root.collectorPath, "--interval", String(root.detailInterval)]
    stdout: SplitParser { onRead: function(line) { root.ingest(line) } }
  }

  Process {
    id: signalProcess
    running: false
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var result = JSON.parse(String(line))
          root.actionError = result.ok ? "Action completed" : String(result.error || "Action failed")
        } catch (error) {
          root.actionError = "Process action returned invalid data"
        }
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    // Coordinate popout lifetime through the panel itself. Using the bar widget as
    // owner makes Omarchy draw its built-in open-panel underline, which this
    // compact status item intentionally does not use.
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(620))
    contentHeight: panel.cappedContentHeight(Style.space(600))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: processTab.editing

      onCloseRequested: {
        if (root.tabIndex === 5 && processTab.handleEscape()) return
        root.close()
      }
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.tabIndex = (root.tabIndex + (dx > 0 ? 1 : 5)) % 6
      }
      onTabRequested: function(direction) {
        root.tabIndex = (root.tabIndex + (direction > 0 ? 1 : 5)) % 6
      }
      onTextKey: function(text) {
        var number = Number(text)
        if (number >= 1 && number <= 6) root.tabIndex = number - 1
      }

      Column {
        anchors.fill: parent
        spacing: Style.spacing.xxl

        Row {
          id: header
          width: parent.width
          height: Style.space(46)
          spacing: Style.spacing.xl

          Rectangle {
            width: Style.space(42)
            height: width
            anchors.verticalCenter: parent.verticalCenter
            radius: Math.max(Style.cornerRadius, Style.space(10))
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
            border.width: Style.spacing.hairline
            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)

            Text {
              anchors.centerIn: parent
              text: "󰓅"
              color: root.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }

          Column {
            width: parent.width - parent.children[0].width - closeButton.width - parent.spacing * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacing.xxs

            Text {
              width: parent.width
              text: "Omarchy Stats"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
            }

            Text {
              width: parent.width
              text: root.snapshot
                ? String(root.snapshot.host || "This computer") + "  ·  up " + Model.duration(root.snapshot.uptimeSeconds)
                : "Collecting live system data…"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
            }
          }

          ActionChip {
            id: closeButton
            anchors.verticalCenter: parent.verticalCenter
            text: "Esc"
            icon: "󰅖"
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            onClicked: root.close()
          }
        }

        Rectangle {
          width: parent.width
          height: Style.space(44)
          radius: Math.max(Style.cornerRadius, Style.space(9))
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.025)
          border.width: Style.spacing.hairline
          border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.055)

          Row {
            anchors.fill: parent
            anchors.margins: Style.spacing.xxs
            spacing: Style.spacing.xxs
            Repeater {
              model: root.tabs
              delegate: NavTab {
                required property var modelData
                required property int index
                width: (parent.width - parent.spacing * 5) / 6
                height: parent.height
                icon: modelData.icon
                label: modelData.label
                selected: root.tabIndex === index
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: root.tabIndex = index
              }
            }
          }
        }

        StackLayout {
          width: parent.width
          height: Math.max(0, parent.height - y)
          currentIndex: root.tabIndex

          CpuTab {
            snapshot: root.snapshot
            history: root.cpuHistory
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
          }
          MemoryTab {
            snapshot: root.snapshot
            history: root.memoryHistory
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
          }
          DisksTab {
            snapshot: root.snapshot
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
          }
          NetworkTab {
            id: networkTab
            snapshot: root.snapshot
            downloadHistory: root.downloadHistory
            uploadHistory: root.uploadHistory
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
          }
          GpuTab {
            snapshot: root.snapshot
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
          }
          ProcessesTab {
            id: processTab
            snapshot: root.snapshot
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            actionError: root.actionError
            onSignalRequested: function(pid, processName, signalName) {
              root.requestSignal(pid, processName, signalName)
            }
            onCloseRequested: root.close()
          }
        }
      }
    }
  }
}
