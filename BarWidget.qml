import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// A small VOLENT indicator for the Omarchy bar. It only reads `volent status
// --short`; starting and stopping happen in a terminal, where the image
// verification and the development-keys notice can be read.
BarWidget {
  id: root
  moduleName: "volent"

  // The plugin's own CLI, next to this file.
  readonly property string cli: decodeURIComponent(
    Qt.resolvedUrl("bin/volent").toString().replace(/^file:\/\//, ""))
  property string nodeState: "down"     // down | starting | up
  property string where: ""

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function openTerminal() {
    var action = root.nodeState === "down" ? "up" : "status"
    Util.execArgv(["omarchy-launch-floating-terminal-with-presentation",
                   "'" + root.cli + "' " + action])
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: statusProc
    command: [root.cli, "status", "--short"]
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = text.trim().split(" ")
        root.nodeState = parts[0] === "up" || parts[0] === "starting" ? parts[0] : "down"
        root.where = parts.length > 1 ? parts[1] : ""
      }
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf132"
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    dimmed: root.nodeState !== "up"
    tooltipText: root.nodeState === "up" ? "VOLENT node on " + root.where + " (click for status)"
      : root.nodeState === "starting" ? "VOLENT node starting on " + root.where
      : "VOLENT: no node running (click to start)"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.openTerminal()
      root.refresh()
    }
  }
}
