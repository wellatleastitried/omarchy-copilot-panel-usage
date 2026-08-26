import QtQuick
import Quickshell
import Quickshell.Io

// Copilot usage collector for the Omarchy agents panel.
// Runs asynchronously to avoid blocking the shell. Outputs to the shared
// state directory where the panel auto-discovers all agent providers.
//
// Optimizations:
// - Debounced file watch: rapid changes don't spawn multiple processes
// - Process state tracking: prevents concurrent collector runs
// - Separate stderr handling: only logs when collection encounters errors
// - Lazy initialization: paths computed once and cached
Item {
  id: controller

  // Plugin integration points
  property var manifest: null
  property var shell: null

  // Cached paths (computed once, not on each invocation)
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

  // Track collection state to prevent overlapping runs
  property bool isCollecting: false
  property int lastCollectTime: 0

  // Panel refresh detection: watch for any provider update in the state dir
  // (not hardcoded to claude.json, more flexible if other collectors change)
  FileView {
    path: controller.stateDir
    watchChanges: true
    printErrors: false
    onFileChanged: collectionTrigger.trigger("sync")
  }

  // Debounce rapid state directory changes. The trigger() method prevents
  // multiple collection runs within the debounce window.
  Timer {
    id: collectionTrigger

    interval: 1000 // 1s debounce window
    running: false
    repeat: false

    // Store reason for logging/debugging purposes
    property string reason: ""

    function trigger(reason_) {
      reason = reason_
      // If already pending, extend the timer; if running, skip
      if (!running) {
        restart()
      } else {
        restart() // Defer next collection
      }
    }

    onTriggered: {
      controller.performCollection(reason)
    }
  }

  // Main collection cycle: executes at startup, then on interval, then on demand
  Timer {
    id: scheduledCollection

    interval: 300000 // 5 minutes between periodic runs
    running: true
    repeat: true
    triggeredOnStart: true

    onTriggered: {
      collectionTrigger.trigger("scheduled")
    }
  }

  // Execute the collector if not already running
  function performCollection(reason) {
    if (!pluginDir) {
      console.warn("copilot-usage", "plugin directory not initialized")
      return
    }

    if (isCollecting) {
      console.debug("copilot-usage", "collection already in progress, skipping:", reason)
      return
    }

    // Throttle: don't re-run within 30 seconds (prevents sync spam)
    var now = Date.now()
    if (lastCollectTime > 0 && (now - lastCollectTime) < 30000) {
      console.debug("copilot-usage", "throttled (30s minimum), reason:", reason)
      return
    }

    lastCollectTime = now
    isCollecting = true

    collectorProcess.start(["/usr/bin/python3", collectorPath, "--write"])
  }

  // Subprocess management: run collector with isolated stderr
  Process {
    id: collectorProcess

    property string startReason: ""

    onRunningChanged: {
      if (!running) {
        controller.isCollecting = false

        // Check exit code; on success, only log if there's stderr
        if (exitCode !== 0) {
          console.warn("copilot-usage", "collector exited with code", exitCode)
        } else if (stderr.text.trim()) {
          console.warn("copilot-usage", "warnings:", stderr.text.trim())
        } else {
          console.debug("copilot-usage", "collection complete")
        }
        stderr.clear()
      }
    }

    stderr: StdioCollector { id: stderr }
    stdout: StdioCollector { } // Collect but ignore
  }
}
