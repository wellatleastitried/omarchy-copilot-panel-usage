# Quick Start

## Install

```bash
omarchy plugin add https://github.com/dougfour/omarchy-copilot-panel-usage.git --enable --yes
```

That's it! The plugin will:
1. Install into `~/.config/omarchy/plugins/dougfour.copilot-panel-usage`
2. Start immediately (shell auto-loads it)
3. Run the collector every 5 minutes via QML timer
4. Write data to `~/.local/state/omarchy/agents/usage/copilot.json`
5. Omarchy's agents panel auto-discovers and displays it

## Verify It's Working

After installation + shell restart, check:

```bash
# Plugin installed and enabled?
omarchy plugin list | grep copilot

# Data file created?
ls -la ~/.local/state/omarchy/agents/usage/copilot.json

# Data looks correct?
cat ~/.local/state/omarchy/agents/usage/copilot.json | jq '{id, name, todaySessions, limits: (.limits | length)}'
```

## See Data in the Panel

Press `Super+A` (or your agents panel shortcut) and look for the Copilot provider.

## Manual Test

Run the collector directly:
```bash
python3 ~/.config/omarchy/plugins/dougfour.copilot-panel-usage/bin/omarchy-agent-usage-copilot --write
```

## Troubleshooting

**Plugin doesn't show in agent panel?**
```bash
# Restart shell to load plugin
omarchy restart shell

# Check plugin is installed and enabled
omarchy plugin list | grep copilot

# Manually run collector
python3 ~/.config/omarchy/plugins/dougfour.copilot-panel-usage/bin/omarchy-agent-usage-copilot --write

# Check output was created
ls -la ~/.local/state/omarchy/agents/usage/copilot.json

# Verify file structure
cat ~/.local/state/omarchy/agents/usage/copilot.json | jq '.id'  # should be "copilot"
```

**No usage data?**
- Verify Copilot CLI is installed: `copilot --version`
- Check session store exists: `ls ~/.copilot/session-store.db`
- Run at least one Copilot prompt to generate data

**Quota showing but usage empty?**
- Local session store (`~/.copilot/session-store.db`) may be empty
- Use Copilot in your editor to generate some activity

For full troubleshooting, see [README.md](README.md).
