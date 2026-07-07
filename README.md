

This repository now runs as a Render web service. The container starts the tracker process, exposes a lightweight HTTP listener, and pings its own health endpoint every 7 minutes so Render does not retire the service for being idle.

## Configuration

Set these environment variables in Render:

| Variable name | Description | Notes |
| --- | --- | --- |
| ARENA_TYPE | `SQUAD` or `FLEET` | Defaults to `SQUAD` when unset |
| DISCORD_WEB_HOOK | Discord webhook URL | Required |
| ALLY_CODES | Comma-separated ally codes | Ignored if `ALLY_CODES_URL` is present |
| ALLY_CODES_URL | URL to a JSON file with players | Recommended for hosted setups |
| PORT | Port for the HTTP listener | Render provides this automatically |
| KEEPALIVE_INTERVAL | Seconds between self-pings | Defaults to `420` (7 minutes) |
| KEEPALIVE_URL | URL to ping to keep service active | Defaults to local `/`; set to your Render public URL for reliable wake-ups |

## Deploy to Render

1. Create a new Web Service in Render and connect this repository.
2. Choose the Docker runtime.
3. Set the service to use the repository root and the included Dockerfile.
4. Add the required environment variables above.
5. Deploy the service and verify that `/healthz` returns a healthy response.

The service listens on the port provided by Render and keeps itself alive by hitting the configured `KEEPALIVE_URL` every 7 minutes.

Set `KEEPALIVE_URL=https://swgoh-tracker-ulw0.onrender.com/` in Render for the external wake-up behavior.

## Notes

- Ally codes can be provided as a comma-separated string such as `123456789,125456189`.
- You will need to create a Discord webhook in the channel of your choice and set `DISCORD_WEB_HOOK` to the generated URL.
- If the tracker process exits unexpectedly, the web listener remains up so the service stays available for Render health checks.
