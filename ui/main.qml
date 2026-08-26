import QtQuick
import Quickshell
import Quickshell.Io

// Headless collector for the Omarchy agents panel.
// Writes ~/.local/state/omarchy/agents/usage/copilot.json; the built-in
// agents panel already watches that directory and displays whatever appears.
Item {
  id: root

  property var manifest: null
  property var shell: null

  readonly property string pluginDir: manifest && manifest.__sourceDir ? String(manifest.__sourceDir) : ""
  readonly property string collector: pluginDir + "/bin/omarchy-agent-usage-copilot"
  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")
  readonly property string claudeRecord: stateHome + "/omarchy/agents/usage/claude.json"

  function collect(force) {
    if (pluginDir === "" || collectProcess.running) return
    var cmd = ["python3", collector, "--write"]
    if (force === true) cmd.push("--force")
    collectProcess.command = cmd
    collectProcess.running = true
  }

  Timer {
    // Run every 5 minutes (300 seconds)
    interval: 300000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.collect(false)
  }

  // Watch for claude.json changes from other collectors.
  // When the user hits 'r' to refresh, the panel updates claude.json.
  // We use that as a cue to also update copilot.json in sync.
  FileView {
    path: root.claudeRecord
    watchChanges: true
    printErrors: false
    onFileChanged: root.collect(false)
  }

  Process {
    id: collectProcess
    running: false
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim() !== "") console.warn("copilot-usage", text.trim())
    }
  }
}
