# Copilot Panel Usage Plugin

Displays Copilot usage and quota in the Omarchy agents panel.

## Install

```bash
omarchy plugin add https://github.com/wellatleastitried/omarchy-copilot-panel-usage.git --enable
```

## Overview

Shows token usage by model, active days, and current quota limits. Reads from Copilot CLI's local session store and fetches quota from GitHub's API (requires editor OAuth tokens).

Data updates every 5 minutes or when you refresh the agents panel.

## License

MIT
