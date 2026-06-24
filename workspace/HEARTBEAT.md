# Heartbeat Checklist

This agent primarily runs via cron, not heartbeat.
If heartbeat is enabled, use this as a fallback.

- If it's between 7:00 AM and 7:45 AM IST and no briefing was sent today, generate and send the morning briefing.
- Otherwise, reply HEARTBEAT_OK.
