import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "ui/Model.js" as Model

BarWidget {
  id: root
  moduleName: "omarchy-stats"

  property real cpuPercent: NaN
  property real memoryPercent: NaN
  property real downloadRate: NaN
  readonly property int refreshInterval: Math.max(1, Math.min(10, Number(setting("refreshSeconds", 1)) || 1))
  readonly property int summaryWidth: Math.max(132, Math.min(220, Number(setting("barWidth", 150)) || 150))
  readonly property int maxCollectorLineLength: 65536
  readonly property string collectorPath: Qt.resolvedUrl("collector.py").toString().replace(/^file:\/\//, "")
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function attachPopup(popup) {
    if (!popup) return
    popup.bar = root.bar
    popup.settings = root.settings
    popup.anchorItem = button
    popup.hostWidget = root
  }

  function open() { if (panelLoader.item) panelLoader.item.openFromHotkey() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: root.attachPopup(panelLoader.item)
  onSettingsChanged: root.attachPopup(panelLoader.item)

  Process {
    id: summaryProcess
    running: true
    command: [
      "python3", root.collectorPath,
      "--summary", "--interval", String(root.refreshInterval),
      "--interface", String(root.setting("netInterface", ""))
    ]
    stdout: SplitParser {
      onRead: function(line) {
        var value = String(line || "")
        if (value.length > root.maxCollectorLineLength) {
          root.cpuPercent = NaN
          root.memoryPercent = NaN
          root.downloadRate = NaN
          return
        }
        try {
          var data = JSON.parse(value)
          root.cpuPercent = Number(data.cpuPercent)
          root.memoryPercent = Number(data.memoryPercent)
          root.downloadRate = Number(data.downloadBytesPerSecond)
        } catch (error) {
          root.cpuPercent = NaN
          root.memoryPercent = NaN
          root.downloadRate = NaN
        }
      }
    }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("ui/Panel.qml")
    visible: false
    onItemChanged: root.attachPopup(item)
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    fixedWidth: root.vertical ? root.barSize : Style.space(root.summaryWidth)
    horizontalMargin: 0
    text: ""
    labelVisible: false
    hasVisualContent: true

    onPressed: function(button) {
      if (button === Qt.LeftButton) root.togglePanel()
    }

    Row {
      anchors.centerIn: parent
      spacing: Style.spaceReal(5)

      Row {
        spacing: Style.spaceReal(2.5)

        Text {
          text: "󰻠"
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: button.fontSize
          renderType: Text.NativeRendering
        }

        Text {
          text: Model.percent(root.cpuPercent)
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: button.fontSize
          renderType: Text.NativeRendering
        }
      }

      Row {
        spacing: Style.spaceReal(2.5)

        Text {
          text: ""
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: button.fontSize
          renderType: Text.NativeRendering
        }

        Text {
          text: Model.percent(root.memoryPercent)
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: button.fontSize
          renderType: Text.NativeRendering
        }
      }

      Row {
        spacing: Style.spaceReal(2.5)

        Text {
          text: "↓"
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: button.fontSize
          renderType: Text.NativeRendering
        }

        Text {
          text: Model.compactRate(root.downloadRate)
          color: button.foreground
          font.family: button.fontFamily
          font.pixelSize: button.fontSize
          renderType: Text.NativeRendering
        }
      }
    }
  }
}
