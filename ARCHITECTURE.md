# Plugin Architecture

## Overview

This plugin is a **headless background worker** — no GUI, just process management for data collection.

```
Omarchy Shell
    ↓
plugin loads ui/main.qml
    ↓
QML Controller (timers, state tracking)
    ↓
Process Manager (spawns collector)
    ↓
bin/omarchy-agent-usage-copilot (Python)
    ↓
~/.local/state/omarchy/agents/usage/copilot.json
    ↑
Agents Panel (watches directory, displays data)
```

## QML Component Design

### State Management
- `isCollecting`: boolean flag prevents concurrent runs
- `lastCollectTime`: throttles to 30s minimum between collections
- `pluginDir`, `collectorPath`, `stateDir`: cached path computations

### Timers

**scheduledCollection** (5 minute interval)
- Periodic background updates
- Runs at startup via `triggeredOnStart`
- Enqueues via `collectionTrigger.trigger("scheduled")`

**collectionTrigger** (1 second debounce)
- Debounces rapid file watch events
- Prevents spawn spam during panel refreshes
- Tracks reason string for logging
- Calls `performCollection()` when debounce window closes

### Reactive Collection

**FileView** watches state directory
- Triggers on any `.json` file changes
- Fires when panel refresh updates claude.json
- Enqueues via `collectionTrigger.trigger("sync")`

### Process Execution

**collectorProcess**
- Started with `start([python3, script, --write])`
- `onRunningChanged` lifecycle:
  - Process start: set `isCollecting = true`
  - Process end: set `isCollecting = false`, check exit code, log stderr
- Captures stdout/stderr via `StdioCollector`

## Performance Optimizations

### Debouncing
When the user presses 'r' to refresh the agents panel, all collectors run nearly simultaneously. Without debouncing, this would spawn the Copilot collector 3+ times in 100ms.

**Solution**: `collectionTrigger` with 1s window coalesces rapid requests into a single execution.

### Throttling
Panel refresh events could fire every few seconds. Without minimum interval enforcement, this would spam API calls.

**Solution**: `lastCollectTime` tracks wall-clock time; collections rejected if < 30s since last run.

### Concurrent Prevention
If collection takes >5 minutes (slow machine, slow API), periodic timer would queue a second collection.

**Solution**: `isCollecting` flag prevents starting new collection while one is already running.

### Path Caching
Original pattern computed paths in getters (called on every timer tick).

**Solution**: `readonly property` with initialization block computed once and cached.

### Selective Logging
Original pattern logged all stderr from any run.

**Solution**: Only log when exit code != 0, or if there are warnings on success.

## Error Handling

- **Plugin dir not found**: Log warning, abort
- **Already collecting**: Skip and log debug (prevents thrashing)
- **Throttled**: Log debug with reason (informational, not an error)
- **Process failure**: Log warning with exit code
- **Process warnings**: Log warnings on success (non-fatal issues)
- **Process success**: Log at debug level (verbose but useful for troubleshooting)

## File Paths

| Path | Purpose |
|------|---------|
| `bin/omarchy-agent-usage-copilot` | Python collector script |
| `ui/main.qml` | QML background worker |
| `~/.copilot/session-store.db` | Copilot CLI session history (read by collector) |
| `~/.config/github-copilot/oauth.json` | Editor OAuth tokens (read by collector) |
| `~/.local/state/omarchy/agents/usage/copilot.json` | Output data (written by collector, watched by panel) |
| `~/.config/omarchy/plugins/dougfour.copilot-panel-usage/` | Plugin installation directory |

## Troubleshooting

**Collection never runs**
- Check `omarchy plugin list` shows plugin is enabled
- Verify `/bin/omarchy-agent-usage-copilot` is executable
- Check omarchy-shell logs: `journalctl -u omarchy-shell.service -f`

**Collection runs but produces no data**
- Run manually: `python3 ~/.config/omarchy/plugins/dougfour.copilot-panel-usage/bin/omarchy-agent-usage-copilot --write`
- Check exit code: `echo $?` should be 0
- Verify session store exists: `ls ~/.copilot/session-store.db`
- Check permissions: collector must be readable+executable

**Collection runs too often / not often enough**
- Scheduled interval: 5 minutes (edit `scheduledCollection.interval`)
- Debounce window: 1 second (edit `collectionTrigger.interval`)
- Throttle minimum: 30 seconds (edit `performCollection` lastCollectTime check)
- Sync reactivity: triggered by any state directory change

## Extension Points

To modify behavior without editing Omarchy core:

1. **Change collection interval**: Edit `scheduledCollection.interval` (milliseconds)
2. **Change debounce window**: Edit `collectionTrigger.interval` 
3. **Change throttle duration**: Edit `30000` in `performCollection`
4. **Add logging**: Modify `console.warn/debug` calls
5. **Change output path**: Edit `stateDir` property
6. **Watch different files**: Add more `FileView` components

No permissions required; all changes local to plugin directory.
