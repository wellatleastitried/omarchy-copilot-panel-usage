import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: controller

  property var manifest: null
  property var shell: null

  readonly property string pluginDir: {
    if (!manifest || !manifest.__sourceDir) return ""
    return String(manifest.__sourceDir)
  }

  readonly property string collectorPath: pluginDir + "/bin/omarchy-agent-usage-copilot"
  readonly property string stateDir: {
    var home = Quickshell.env("HOME") || ""
    var xdgState = Quickshell.env("XDG_STATE_HOME")
    return (xdgState || home + "/.local/state") + "/omarchy/agents/usage"
  }

  property bool isCollecting: false
  property int lastCollectTime: 0

  FileView {
    path: controller.stateDir
    watchChanges: true
    printErrors: false
    onFileChanged: collectionTrigger.trigger("sync")
  }

  Timer {
    id: collectionTrigger
    interval: 1000
    running: false
    repeat: false
    property string reason: ""

    function trigger(reason_) {
      reason = reason_
      restart()
    }

    onTriggered: controller.performCollection(reason)
  }

  Timer {
    id: scheduledCollection
    interval: 300000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: collectionTrigger.trigger("scheduled")
  }

  function performCollection(reason) {
    if (!pluginDir) return
    if (isCollecting) return

    var now = Date.now()
    if (lastCollectTime > 0 && (now - lastCollectTime) < 30000) return

    lastCollectTime = now
    isCollecting = true
    collectorProcess.command = ["/usr/bin/python3", collectorPath, "--write"]
    collectorProcess.running = true
  }

  Process {
    id: collectorProcess

    onRunningChanged: {
      if (running) return
      controller.isCollecting = false
      if (exitCode !== 0 || stderr.text.trim()) {
        console.warn("copilot-usage", exitCode !== 0 ? "exit " + exitCode : stderr.text.trim())
      }
      stderr.clear()
    }

    stderr: StdioCollector { id: stderr }
    stdout: StdioCollector { }
  }
}
