# Quick Start

## Install

```bash
omarchy plugin add https://github.com/dougfour/omarchy-copilot-panel-usage.git --enable
```

That's it! The plugin will:
1. Start immediately
2. Run the collector every 5 minutes
3. Write data to `~/.local/state/omarchy/agents/usage/copilot.json`
4. Omarchy's agents panel auto-discovers and displays it

## Verify It's Working

Check the state file was created:
```bash
cat ~/.local/state/omarchy/agents/usage/copilot.json
```

Or run the collector manually:
```bash
python3 ~/.omarchy/plugins/omarchy-copilot-panel-usage/bin/omarchy-agent-usage-copilot
```

## See Data in the Panel

Press `Super+A` (or your agents panel shortcut) and look for the Copilot provider.

## Troubleshooting

**Plugin doesn't show in agent panel?**
```bash
# Check plugin is installed
omarchy plugin status omarchy-copilot-panel-usage

# Manually run collector
~/.omarchy/plugins/omarchy-copilot-panel-usage/bin/omarchy-agent-usage-copilot --write

# Check output was created
ls -la ~/.local/state/omarchy/agents/usage/copilot.json

# Verify Omarchy sees it
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
