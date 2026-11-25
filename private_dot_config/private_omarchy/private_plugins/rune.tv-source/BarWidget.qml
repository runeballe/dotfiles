import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Two buttons: Xbox and PC. Each runs `tv-remote xbox|pc`
// (~/.local/bin/tv-remote, config in ~/.config/tv-remote.conf).
BarWidget {
  id: root
  moduleName: "rune.tv-source"

  readonly property var sources: [
    { id: "xbox", icon: "󰖺", tip: "TV: switch to Xbox" },
    { id: "pc", icon: "󰍹", tip: "TV: switch to PC" }
  ]

  implicitWidth: row.implicitWidth
  implicitHeight: barSize

  Process {
    id: action
    running: false
    property string source: "pc"
    command: ["sh", "-c", "exec \"$HOME/.local/bin/tv-remote\" \"$1\" || notify-send -u critical 'TV' 'Could not reach the TV'", "sh", action.source]
  }

  Row {
    id: row
    anchors.centerIn: parent
    Repeater {
      model: root.sources
      Item {
        required property var modelData
        width: root.barSize
        height: root.barSize

        Text {
          anchors.centerIn: parent
          text: modelData.icon
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
          onEntered: if (root.bar) root.bar.showTooltip(parent, modelData.tip)
          onExited: if (root.bar) root.bar.hideTooltip(parent)
          onClicked: {
            if (action.running) return
            action.source = modelData.id
            action.running = true
          }
        }
      }
    }
  }
}
