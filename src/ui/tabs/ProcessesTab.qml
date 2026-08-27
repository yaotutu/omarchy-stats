import QtQuick
import QtQuick.Controls as Controls
import qs.Commons
import qs.Ui as Ui
import "../components"
import "../Model.js" as Model

Item {
  id: root
  property var snapshot: null
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property string query: ""
  property string sortKey: "cpu"
  property bool descending: true
  property var selectedProcess: null
  property string pendingSignal: ""
  property int confirmationStep: 0
  property string actionError: ""

  readonly property var processData: snapshot && snapshot.processes ? snapshot.processes : null
  readonly property var rows: Model.processRows(processData ? processData.items : [], query, sortKey, descending)
  readonly property bool editing: filterInput.activeFocus
  readonly property color dim: Color.muted
  signal signalRequested(int pid, string processName, string signalName)
  signal closeRequested()

  function cancelConfirmation() {
    pendingSignal = ""
    confirmationStep = 0
  }

  function reconcileSelection() {
    if (!selectedProcess || !processData) return
    var items = processData.items || []
    for (var index = 0; index < items.length; index++) {
      if (Number(items[index].pid) === Number(selectedProcess.pid)) {
        selectedProcess = items[index]
        return
      }
    }
    selectedProcess = null
    cancelConfirmation()
  }

  onSnapshotChanged: reconcileSelection()

  function beginSignal(name) {
    if (!selectedProcess) return
    pendingSignal = name
    confirmationStep = 1
  }

  function confirmSignal() {
    if (!selectedProcess || !pendingSignal) return
    if (pendingSignal === "KILL" && confirmationStep < 2) {
      confirmationStep = 2
      return
    }
    signalRequested(Number(selectedProcess.pid), String(selectedProcess.name), pendingSignal)
    cancelConfirmation()
  }

  function handleEscape() {
    if (filterInput.activeFocus) {
      filterInput.focus = false
      return true
    }
    if (pendingSignal) {
      cancelConfirmation()
      return true
    }
    return false
  }

  Column {
    anchors.fill: parent
    spacing: Style.spacing.xl

    Row {
      width: parent.width
      height: Style.spacing.controlHeight
      spacing: Style.spacing.lg

      Ui.TextField {
        id: filterInput
        width: Math.max(Style.space(250), parent.width - sortButtons.width - countLabel.width - parent.spacing * 2)
        height: parent.height
        placeholderText: "Search processes, commands, users, or PID"
        text: root.query
        foreground: root.foreground
        accent: root.accent
        horizontalPadding: Style.spacing.xl
        verticalPadding: Style.spacing.sm
        onTextChanged: {
          if (root.query === text) return
          root.query = text
          root.selectedProcess = null
          root.cancelConfirmation()
        }
        Keys.onEscapePressed: function(event) {
          if (root.pendingSignal) root.cancelConfirmation()
          else root.closeRequested()
          event.accepted = true
        }
      }

      Text {
        id: countLabel
        width: Style.space(58)
        anchors.verticalCenter: parent.verticalCenter
        text: String(root.rows.length) + " shown"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        horizontalAlignment: Text.AlignHCenter
      }

      Row {
        id: sortButtons
        height: parent.height
        spacing: Style.spacing.sm
        ActionChip {
          height: parent.height
          text: "CPU" + (root.sortKey === "cpu" ? (root.descending ? " ↓" : " ↑") : "")
          selected: root.sortKey === "cpu"
          foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
          onClicked: {
            if (root.sortKey === "cpu") root.descending = !root.descending
            else { root.sortKey = "cpu"; root.descending = true }
          }
        }
        ActionChip {
          height: parent.height
          text: "RAM" + (root.sortKey === "memory" ? (root.descending ? " ↓" : " ↑") : "")
          selected: root.sortKey === "memory"
          foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
          onClicked: {
            if (root.sortKey === "memory") root.descending = !root.descending
            else { root.sortKey = "memory"; root.descending = true }
          }
        }
      }
    }

    Row {
      width: parent.width
      height: Math.max(0, parent.height - y)
      spacing: Style.spacing.xl

      Rectangle {
        id: listCard
        width: root.selectedProcess ? parent.width - Style.space(224) - parent.spacing : parent.width
        height: parent.height
        radius: Math.max(Style.cornerRadius, Style.space(9))
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.028)
        border.width: Style.spacing.hairline
        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07)

        Column {
          anchors.fill: parent
          anchors.margins: Style.spacing.md
          spacing: Style.spacing.xxs

          Rectangle {
            width: parent.width
            height: Style.space(30)
            radius: Math.max(Style.cornerRadius, Style.space(6))
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.045)

            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.spacing.xl
              anchors.rightMargin: Style.spacing.xl
              Text { width: Style.space(52); anchors.verticalCenter: parent.verticalCenter; text: "PID"; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
              Text { width: Math.max(0, parent.width - Style.space(180)); anchors.verticalCenter: parent.verticalCenter; text: "PROCESS"; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
              Text { width: Style.space(58); anchors.verticalCenter: parent.verticalCenter; text: "CPU"; horizontalAlignment: Text.AlignRight; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
              Text { width: Style.space(70); anchors.verticalCenter: parent.verticalCenter; text: "MEM"; horizontalAlignment: Text.AlignRight; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true }
            }
          }

          ListView {
            id: processList
            width: parent.width
            height: Math.max(0, parent.height - y)
            clip: true
            spacing: Style.spacing.xxs
            model: root.rows
            boundsBehavior: Flickable.StopAtBounds
            Controls.ScrollBar.vertical: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded }

            delegate: Rectangle {
              required property var modelData
              width: processList.width
              height: Style.space(34)
              radius: Math.max(Style.cornerRadius, Style.space(6))
              readonly property bool chosen: root.selectedProcess && Number(root.selectedProcess.pid) === Number(modelData.pid)
              color: chosen
                ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
                : (rowMouse.containsMouse ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.055) : "transparent")

              Behavior on color { ColorAnimation { duration: 90 } }

              Rectangle {
                visible: parent.chosen
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(3)
                height: parent.height - Style.spacing.lg
                radius: width / 2
                color: root.accent
              }

              Row {
                anchors.fill: parent
                anchors.leftMargin: Style.spacing.xl
                anchors.rightMargin: Style.spacing.xl
                Text { width: Style.space(52); anchors.verticalCenter: parent.verticalCenter; text: String(modelData.pid); color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
                Text { width: Math.max(0, parent.width - Style.space(180)); anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; font.bold: parent.parent.chosen; elide: Text.ElideRight }
                Text { width: Style.space(58); anchors.verticalCenter: parent.verticalCenter; text: Model.percent(modelData.cpuPercent, 1); horizontalAlignment: Text.AlignRight; color: Number(modelData.cpuPercent || 0) > 20 ? root.accent : root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: Number(modelData.cpuPercent || 0) > 20 }
                Text { width: Style.space(70); anchors.verticalCenter: parent.verticalCenter; text: Model.bytes(modelData.residentBytes, false); horizontalAlignment: Text.AlignRight; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
              }

              MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.selectedProcess = modelData
                  root.cancelConfirmation()
                }
              }
            }
          }
        }
      }

      Rectangle {
        id: detailCard
        visible: root.selectedProcess !== null
        width: Style.space(224)
        height: parent.height
        radius: Math.max(Style.cornerRadius, Style.space(9))
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.038)
        border.width: Style.spacing.hairline
        border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.085)

        Flickable {
          anchors.fill: parent
          anchors.margins: Style.spacing.xxl
          clip: true
          contentWidth: width
          contentHeight: details.implicitHeight
          boundsBehavior: Flickable.StopAtBounds
          Controls.ScrollBar.vertical: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded }

          Column {
            id: details
            width: parent.width
            spacing: Style.spacing.lg

            Row {
              width: parent.width
              spacing: Style.spacing.lg
              Rectangle {
                width: Style.space(34)
                height: width
                radius: Math.max(Style.cornerRadius, Style.space(8))
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
                Text { anchors.centerIn: parent; text: "󰄉"; color: root.accent; font.family: root.fontFamily; font.pixelSize: Style.font.title }
              }
              Column {
                width: parent.width - parent.children[0].width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                Text { width: parent.width; text: root.selectedProcess ? root.selectedProcess.name : ""; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.bold: true; elide: Text.ElideRight }
                Text { width: parent.width; text: root.selectedProcess ? "PID " + root.selectedProcess.pid : ""; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption }
              }
            }

            Rectangle { width: parent.width; height: Style.spacing.hairline; color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08) }

            StatPair { width: parent.width; label: "CPU"; value: root.selectedProcess ? Model.percent(root.selectedProcess.cpuPercent, 1) : "—"; foreground: root.foreground; fontFamily: root.fontFamily; emphasize: true }
            StatPair { width: parent.width; label: "Memory"; value: root.selectedProcess ? Model.bytes(root.selectedProcess.residentBytes, false) : "—"; foreground: root.foreground; fontFamily: root.fontFamily; emphasize: true }
            StatPair { width: parent.width; label: "User"; value: root.selectedProcess ? root.selectedProcess.user : "—"; foreground: root.foreground; fontFamily: root.fontFamily }
            StatPair { width: parent.width; label: "Parent"; value: root.selectedProcess ? String(root.selectedProcess.parentPid) : "—"; foreground: root.foreground; fontFamily: root.fontFamily }
            StatPair { width: parent.width; label: "State"; value: root.selectedProcess ? root.selectedProcess.state : "—"; foreground: root.foreground; fontFamily: root.fontFamily }
            StatPair { width: parent.width; label: "Threads"; value: root.selectedProcess ? String(root.selectedProcess.threads) : "—"; foreground: root.foreground; fontFamily: root.fontFamily }

            Text {
              width: parent.width
              text: root.selectedProcess ? (root.selectedProcess.command || "No command line") : ""
              wrapMode: Text.WrapAnywhere
              maximumLineCount: 4
              elide: Text.ElideRight
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Text { text: "PROCESS CONTROL"; color: root.dim; font.family: root.fontFamily; font.pixelSize: Style.font.caption; font.bold: true; font.letterSpacing: 0.8 }

            Flow {
              width: parent.width
              spacing: Style.spacing.sm
              ActionChip { text: "Pause"; icon: "󰏤"; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily; onClicked: root.beginSignal("STOP") }
              ActionChip { text: "Resume"; icon: "󰐊"; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily; onClicked: root.beginSignal("CONT") }
              ActionChip { text: "Quit"; icon: "󰩈"; destructive: true; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily; onClicked: root.beginSignal("TERM") }
              ActionChip { text: "Kill"; icon: "󰆴"; destructive: true; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily; onClicked: root.beginSignal("KILL") }
            }

            Rectangle {
              width: parent.width
              height: confirmColumn.implicitHeight + Style.spacing.xl * 2
              visible: root.pendingSignal !== ""
              radius: Math.max(Style.cornerRadius, Style.space(7))
              color: Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.10)
              border.width: Style.spacing.hairline
              border.color: Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.28)

              Column {
                id: confirmColumn
                anchors.fill: parent
                anchors.margins: Style.spacing.xl
                spacing: Style.spacing.lg
                Text {
                  width: parent.width
                  wrapMode: Text.WordWrap
                  text: root.pendingSignal === "KILL" && root.confirmationStep === 2
                    ? "Final confirmation: force-kill this process?"
                    : "Confirm " + root.pendingSignal + " for PID " + (root.selectedProcess ? root.selectedProcess.pid : "") + "?"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
                Row {
                  spacing: Style.spacing.sm
                  ActionChip { text: root.pendingSignal === "KILL" && root.confirmationStep === 1 ? "Continue" : "Confirm"; destructive: true; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily; onClicked: root.confirmSignal() }
                  ActionChip { text: "Cancel"; foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily; onClicked: root.cancelConfirmation() }
                }
              }
            }

            Text {
              visible: root.actionError !== ""
              width: parent.width
              wrapMode: Text.WordWrap
              text: root.actionError
              color: root.actionError === "Action completed" ? root.accent : Color.urgent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }
      }
    }
  }
}
