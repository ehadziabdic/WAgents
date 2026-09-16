# wagents plugin

This directory is generated from the repository source by `npm run build:plugin`.

Skills, agent roles, slash-command documentation, and lifecycle hooks are portable.
Slash commands are documented under `commands/`; lifecycle hooks are under `hooks/`.

MCP connections are intentionally not bundled: they can require OAuth, local vault access, paid licenses, or privileged credentials. Use the repository [MCP setup guide](../../mcp/README.md).
