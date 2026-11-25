import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// One HDMI-input button. Clicking it reveals two buttons, Xbox and PC, which
// switch the Samsung TV input (the bundled `tv-remote xbox|pc`;
// key sequences and TV address in ~/.config/tv-remote.conf). Picking one, or
// clicking the input button again, folds them away.
BarWidget {
  id: root
  moduleName: "rune.tv-source"

  property bool open: false

  // The plugin's own copy of tv-remote (Qt.resolvedUrl gives a file:// URL).
  readonly property string helper: String(Qt.resolvedUrl("tv-remote")).replace(/^file:\/\//, "")

  readonly property var sources: [
    { id: "xbox", icon: "\u{F05BA}", tip: "TV: switch to Xbox" },
    { id: "pc", icon: "\u{F0379}", tip: "TV: switch back to PC" }
  ]

  implicitWidth: row.implicitWidth
  implicitHeight: barSize

  Process {
    id: action
    running: false
    property string source: "pc"
    command: ["sh", "-c", "exec \"$1\" \"$2\" || notify-send -u critical 'TV' 'Could not reach the TV'", "sh", root.helper, action.source]
  }

  // Folds the choices away if nothing is picked.
  Timer {
    id: autoClose
    interval: 6000
    onTriggered: root.open = false
  }

  component IconButton: Item {
    id: button
    property string icon: ""
    property string tip: ""
    property real dim: 0.75
    signal clicked()
    width: root.barSize
    height: root.barSize

    Text {
      anchors.centerIn: parent
      text: button.icon
      color: Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Math.round(root.barSize * 0.55)
      opacity: mouse.containsMouse ? 1.0 : button.dim
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: if (root.bar) root.bar.showTooltip(button, button.tip)
      onExited: if (root.bar) root.bar.hideTooltip(button)
      onClicked: button.clicked()
    }
  }

  Row {
    id: row
    anchors.centerIn: parent

    IconButton {
      icon: "\u{F0841}"
      tip: root.open ? "Hide TV sources" : "TV source"
      dim: root.open ? 1.0 : 0.75
      onClicked: {
        root.open = !root.open
        if (root.open) autoClose.restart()
      }
    }

    Repeater {
      model: root.open ? root.sources : []
      IconButton {
        required property var modelData
        icon: modelData.icon
        tip: modelData.tip
        onClicked: {
          if (action.running) return
          action.source = modelData.id
          action.running = true
          root.open = false
        }
      }
    }
  }
}
