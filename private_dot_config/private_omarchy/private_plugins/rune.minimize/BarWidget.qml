import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// An invisible click target at the end of the bar.
// Left-click minimizes the active window (tiled or floating),
// right-click brings the most recently minimized window back.
BarWidget {
  id: root
  moduleName: "rune.minimize"

  implicitWidth: barSize
  implicitHeight: barSize

  Process {
    id: action
    running: false
    property string verb: "minimize"
    command: ["sh", "-c", "exec \"$HOME/.local/bin/minimize-window\" \"$1\"", "sh", action.verb]
  }

  function run(verb) {
    if (action.running) return
    action.verb = verb
    action.running = true
  }

  Text {
    anchors.centerIn: parent
    text: "—"
    color: Color.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Math.round(root.barSize * 0.6)
    font.bold: true
    opacity: mouse.containsMouse ? 1.0 : 0.75
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => root.run(mouse.button === Qt.RightButton ? "restore" : "minimize")
  }
}
