# Email Ingest Cloudflare Worker

This Cloudflare Worker receives inbound email via Cloudflare Email Routing, parses the raw MIME message using `postal-mime`, and forwards a structured JSON payload to the Rails app webhook endpoint (`POST /webhooks/inbound_email`).

## Prerequisites

- [Node.js ≥ 18](https://nodejs.org/) and npm
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/) (`npm install -g wrangler` or use `npx wrangler`)
- A Cloudflare account with your domain zone

## Setup steps

### 1. Generate the shared webhook secret

```bash
openssl rand -hex 32
```

Copy the output — you'll need it in steps 2 and 6.

### 2. Add the secret to Rails credentials

On your local machine (development credentials) or via Hatchbox SSH for production:

```bash
# Production
ruby bin/rails credentials:edit --environment production
```

Add the following line:

```yaml
inbound_email_webhook_secret: <your-secret-here>
```

Save and commit the updated `.enc` file. Alternatively, set the `INBOUND_EMAIL_WEBHOOK_SECRET` environment variable in Hatchbox (it takes precedence over credentials).

### 3. Install Worker dependencies

```bash
cd cloudflare-worker
npm install
```

### 4. Authenticate with Cloudflare

```bash
npx wrangler login
```

Follow the browser prompt to authorise Wrangler with your Cloudflare account.

### 5. Deploy the Worker

Update `WEBHOOK_URL` in `wrangler.toml` to your production domain, then:

```bash
npx wrangler deploy
```

### 6. Set the webhook secret in the Worker

```bash
npx wrangler secret put WEBHOOK_SECRET
```

Paste the same secret you added to Rails credentials in step 2.

### 7. Update Cloudflare Email Routing

1. Log in to the [Cloudflare dashboard](https://dash.cloudflare.com)
2. Select your domain zone
3. Go to **Email** → **Email Routing** → **Routing Rules**
4. Create or edit a rule for your inbound address (e.g. `hello@yourdomain.com`)
5. Change the **Action** from `Send to an email` to `Send to a Worker`
6. Select **email-ingest** from the Worker dropdown
7. Save

### 8. Test the integration

Send an email to your inbound address from a personal inbox, then check `/admin/inbox` in the admin area — the email should appear within seconds.

To inspect Worker logs in real time:

```bash
npx wrangler tail email-ingest
```

## Environment variables

| Variable | Where set | Purpose |
|---|---|---|
| `WEBHOOK_URL` | `wrangler.toml` | Full URL of the Rails webhook endpoint |
| `WEBHOOK_SECRET` | Wrangler secret | Shared secret verified by Rails |

## Updating the webhook URL

If the app moves to a new domain, update `WEBHOOK_URL` in `wrangler.toml` and re-deploy:

```bash
npx wrangler deploy
```
