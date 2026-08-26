# Copilot Panel Usage Plugin

Display GitHub Copilot usage and quota information in the Omarchy agents panel widget as a self-contained plugin.

## Features

- **Session History**: Token counts aggregated from Copilot CLI's local session store (`~/.copilot/session-store.db`)
- **Quota Limits**: Real-time quota usage and reset dates from GitHub's API
- **Model Breakdown**: Token usage split by AI model
- **Active Days**: Total number of days with activity
- **Exhausted Quota**: User-friendly message when premium requests are depleted
- **Zero Core Modifications**: Works without modifying Omarchy's base files

## How It Works

The plugin runs a Python collector every 5 minutes that:
1. Reads token usage from `~/.copilot/session-store.db`
2. Fetches quota limits from GitHub's API (if editor OAuth tokens available)
3. Writes the result to `~/.local/state/omarchy/agents/usage/copilot.json`

The Omarchy agents panel already watches this directory and automatically displays any JSON files found there.

## Installation

```bash
omarchy plugin add https://github.com/dougfour/omarchy-copilot-panel-usage.git --enable
```

Or without auto-enabling:

```bash
omarchy plugin add https://github.com/dougfour/omarchy-copilot-panel-usage.git
omarchy plugin enable omarchy-copilot-panel-usage
```

## Requirements

- Omarchy (tested on 0.1.0+)
- Python 3.10+
- Copilot CLI installed with session history (`~/.copilot/session-store.db`)
- Optional: Editor plugin OAuth tokens for quota display (VS Code, JetBrains, or copilot.vim)

## Data Sources

### Session History (Always Available)
Reads from the Copilot CLI's local SQLite database at `~/.copilot/session-store.db` (configurable via `COPILOT_HOME`):
- Total token counts by model and day
- Today's prompt count and session count
- Active days (lifetime, not capped at 7)

### Quota Limits (Requires Editor Auth)
Fetches from GitHub's `copilot_internal/user` API using OAuth tokens from editor plugins:
- Stored at `~/.config/github-copilot/oauth.json` (VS Code, JetBrains, copilot.vim)
- Shows premium request limits and current usage
- Displays reset date for quota

**Note**: The Copilot CLI has its own separate session store and does not store OAuth tokens. Quota display requires signing into an editor plugin.

## Usage

Once installed and enabled, the agents panel will automatically show Copilot as an available provider. The collector runs:
- Every 5 minutes automatically
- When you press 'r' to refresh the agents panel
- On startup

Click the Copilot entry to view:
- Today's statistics (prompts, sessions)
- Historical token usage by model
- Current quota and reset date

## Troubleshooting

**Copilot doesn't appear in the agents panel**
- Run the collector manually: `python3 bin/omarchy-agent-usage-copilot --write`
- Check that `~/.local/state/omarchy/agents/usage/copilot.json` was created
- Verify the plugin is enabled: `omarchy plugin status omarchy-copilot-panel-usage`

**No data showing**
- Verify `~/.copilot/session-store.db` exists and contains data
- Check COPILOT_HOME environment variable if using custom location
- Run collector manually to see output: `python3 bin/omarchy-agent-usage-copilot`

**No quota data**
- Quota display requires editor OAuth tokens (VS Code, JetBrains, copilot.vim)
- Verify token file exists at `~/.config/github-copilot/oauth.json`
- Local usage stats will display even without quota data

## Plugin Architecture

```
omarchy-copilot-panel-usage/
├── plugin.json              # Plugin metadata
├── bin/
│   └── omarchy-agent-usage-copilot  # Python collector
├── ui/
│   └── main.qml            # QML component (runs collector on timer)
├── assets/
│   ├── copilot.svg         # Dark mode icon
│   └── copilot-light.svg   # Light mode icon
└── README.md
```

The QML component is a headless background worker that:
- Runs the collector every 5 minutes
- Watches for changes from other collectors to stay in sync
- Writes output to the standard Omarchy state directory
- Requires zero modifications to Omarchy core

## License

MIT

## Contributing

Issues and PRs welcome at https://github.com/dougfour/omarchy-copilot-panel-usage

## Related

- [Copilot PR #7798](https://github.com/basecamp/omarchy/pull/7798) - Original PR for core integration (if merged, this plugin becomes optional)
