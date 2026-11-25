import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// One button with an HDMI-input icon: switches the Samsung TV to the Xbox
// (runs `tv-remote xbox` = XBOX key in ~/.config/tv-remote.conf, via ~/.local/bin/tv-remote; TV address in ~/.config/tv-remote.conf).
BarWidget {
  id: root
  moduleName: "rune.tv-source"

  implicitWidth: barSize
  implicitHeight: barSize

  Process {
    id: action
    running: false
    command: ["sh", "-c", "exec \"$HOME/.local/bin/tv-remote\" xbox || notify-send -u critical 'TV' 'Could not reach the TV'"]
  }

  Text {
    anchors.centerIn: parent
    text: "\u{F0841}"
    color: Color.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Math.round(root.barSize * 0.55)
    opacity: mouse.containsMouse ? 1.0 : 0.75
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: if (root.bar) root.bar.showTooltip(root, "TV: switch to Xbox")
    onExited: if (root.bar) root.bar.hideTooltip(root)
    onClicked: if (!action.running) action.running = true
  }
}
