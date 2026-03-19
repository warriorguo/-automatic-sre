---
name: claude-status
description: Check Claude service status. Use this skill when users ask about Claude's operational status, whether Claude is down, if the Claude API is working, any active incidents or outages on Claude, or general Claude health checks. Trigger phrases include: "Claude status", "is Claude down", "Claude API working", "any incidents on Claude", "check Claude health", "Claude outage", "is Claude operational", "Claude service status", "Claude正常吗", "Claude有问题吗", "Claude挂了吗".
---

# Claude Status Skill

When this skill is invoked, fetch the Claude status API and display the results in a clear, concise format.

## Instructions

1. Fetch https://status.claude.com/api/v2/summary.json using WebFetch
2. Parse and display:
   - Overall system status
   - Each component name and its status
   - Any active incidents (title, impact, status, last update)
3. Use these status indicators:
   - `operational` → ✓
   - `degraded_performance` → ⚠
   - `partial_outage` → ⚠
   - `major_outage` → ✗
   - `under_maintenance` → 🔧
   - `none` (overall indicator) → ✓ All Systems Operational

## Output Format

```
Claude Service Status
Last updated: <updated_at from page object>

Overall: <indicator emoji> <description>

Components:
  ✓ claude.ai — operational
  ✓ Claude API — operational
  ... (all components)

Incidents: None
```

If there are active incidents, list each one:
```
Incidents:
  ⚠ <incident name>
     Impact: <impact level>
     Status: <status>
     Updated: <updated_at>
```

## Prompt to Use

Use this exact prompt when calling WebFetch:

URL: https://status.claude.com/api/v2/summary.json

Prompt: "Extract and return: (1) page.updated_at, (2) status.indicator and status.description, (3) for each component in components array return name and status, (4) for each incident in incidents array return name, impact, status, and updated_at. Return as structured data."

Then format the output using the status indicator mapping above and display it clearly.
