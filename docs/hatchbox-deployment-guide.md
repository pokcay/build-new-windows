# Hatchbox deployment guide

Quick reference for deploying an app generated from this template to Hatchbox. Steps are in the order you'd do them in the Hatchbox UI.

## 1. Spin up a cluster (server)

Create a new cluster in Hatchbox — typically on Digital Ocean. The cluster needs these roles:

- **Web** — Rails app + the SSR Node process
- **Worker** — Solid Queue background jobs (`bin/jobs`)
- **Cron** — scheduled jobs (only needed if you add any; safe to include by default)
- **PostgreSQL** — the single database that backs Active Record, Solid Queue, Solid Cache, and Solid Cable

A single-server cluster with all roles is fine for a small app. Split them later if you outgrow it.

Make sure the server image has compatible Ruby and Node versions — this app expects:

- Ruby `3.3.6` (from `.ruby-version`)
- Node `22.12.0` (from `.nvmrc`)

## 2. Create the app

- Hatchbox dashboard → New App
- Connect your GitHub repo and pick the branch to deploy (e.g. `main` or `staging`)
- (Optional) Enable auto-deploy on push for that branch

## 3. Set environment variables

App → **Environment**. Required and recommended values:

### Required (all environments)

| Variable | Example | Notes |
| --- | --- | --- |
| `RAILS_MASTER_KEY` | Contents of `config/master.key` or `config/credentials/production.key` | Required to decrypt Rails credentials. Do **not** commit the key file. |
| `APP_HOST` | `yourdomain.com` | Used by mailer URL helpers and `config/sitemap.rb`. Without it, mailer links + sitemap fall back to `example.com`. Host only — no `https://` prefix. |

### Email (production / staging)

| Variable | Example | Notes |
| --- | --- | --- |
| `MAIL_FROM` | `App <noreply@notification.yourdomain.com>` | Default `from:` header. Domain must be Resend-verified. |
| `MAIL_REPLY_TO` | `hello@yourdomain.com` | `reply_to:` header for user replies (route via Cloudflare Email Routing — step 10). |

### Credentials (encrypted in repo — no env var needed)

`RESEND_API_KEY` and `inbound_email_webhook_secret` live in `config/credentials/<env>.yml.enc`. The initializers read from credentials first, with an ENV fallback. **You do not need to set these as Hatchbox env vars** — `RAILS_MASTER_KEY` unlocks them.

Use `ruby bin/rails runner bin/setup_credentials KEY VALUE` to add keys without opening an editor:

```bash
ruby bin/rails runner bin/setup_credentials resend_api_key re_xxx
ruby bin/rails runner bin/setup_credentials inbound_email_webhook_secret $(openssl rand -hex 32)
```

If you'd rather use ENV for quick rotation, the names are `RESEND_API_KEY` and `INBOUND_EMAIL_WEBHOOK_SECRET`.

### Optional / situational

| Variable | Value | When to set it |
| --- | --- | --- |
| `INERTIA_SSR` | `1` or `0` | SSR is **on by default in production** (see `config/initializers/inertia_rails.rb`). Set `0` to force-disable, e.g. for debugging. |
| `INERTIA_SSR_URL` | `http://localhost:13714` | Only needed if you move the SSR process to a non-default port. |
| `DATABASE_URL` | postgres URL | Hatchbox usually sets this automatically when you attach the database (step 4). Only override if you're pointing at an external database. |

For staging + production split: create two Hatchbox apps (one per branch), each with its own `RAILS_MASTER_KEY` from `config/credentials/staging.key` and `config/credentials/production.key`.

## 4. Create the database

App → **Databases** → click the button to create a PostgreSQL database for this app. Hatchbox provisions it on the PostgreSQL-role server and wires `DATABASE_URL` into the app automatically.

This single database is also used by Solid Queue, Solid Cache, and Solid Cable — no separate databases needed (see `CLAUDE.md`).

## 5. Set up the domain

App → **Domains & SSL**:

- Add your domain (e.g. `yourdomain.com` and/or `www.yourdomain.com`)
- Point DNS at the Hatchbox server IP (A record for apex, CNAME for `www`)
- Let Hatchbox auto-provision Let's Encrypt SSL once DNS propagates

## 6. Create the SSR process

App → **Processes** → Add Process. This runs the long-lived Node server that handles Inertia SSR requests from Rails.

| Field | Value |
| --- | --- |
| Runs on | **web** |
| Process name | `ssr` |
| Start command | `bin/vite ssr` |
| Reload command | *(empty)* |
| Stop command | *(empty)* |
| Restart this process on every deploy | ✅ checked |
| Socket activation | unchecked |

**Why this matters:** the Inertia Rails renderer POSTs page renders to this Node process at `http://localhost:13714`. If the process isn't running, Inertia silently falls back to client-only rendering — crawlers (Google, GPTBot, ClaudeBot, etc.) see an empty `<div id="app">` on public pages.

The SSR bundle itself (`public/vite-ssr/ssr.js`) is built automatically during `assets:precompile` because `config/vite.json` has `"ssrBuildEnabled": true`. No extra build step needed.

## 7. Create the jobs process

App → **Processes** → Add Process. This runs Solid Queue.

| Field | Value |
| --- | --- |
| Runs on | **worker** |
| Process name | `jobs` |
| Start command | `bin/jobs` |
| Restart this process on every deploy | ✅ checked |

## 8. Verify the Resend sending domain

Outbound email goes through Resend (`config.action_mailer.delivery_method = :resend`). Resend will only deliver to arbitrary recipients from a verified domain.

1. Resend dashboard → **Domains** → **Add Domain** → e.g. `notification.yourdomain.com`
2. Add the DNS records Resend shows (SPF TXT, DKIM CNAME, optionally DMARC) to your DNS provider.
3. Wait for Resend to mark the domain **Verified** before relying on production sends. Until then, `MAIL_FROM` can fall back to `App <onboarding@resend.dev>` (delivers only to the Resend account owner's email — useful for sanity tests).
4. **Do not add an MX record to the notification subdomain** — you don't receive email there.

## 9. Set up Cloudflare Email Routing for replies

`MAIL_REPLY_TO=hello@yourdomain.com` puts a real inbox in the Reply-To header so user replies don't disappear into the noreply sender.

1. Cloudflare dashboard → your zone → **Email** → **Email Routing** → **Enable Email Routing**
2. **Destination Addresses** → add a personal inbox and verify it
3. **Routing Rules** → **Custom Address** → match `hello@yourdomain.com` → action `Send to an email` → pick the verified destination
4. Test by sending email to `hello@yourdomain.com`

## 10. Set up inbound email inbox (optional)

To capture inbound email in `/admin/inbox` instead of forwarding to Gmail, deploy the Cloudflare Worker in `cloudflare-worker/`. See **`cloudflare-worker/README.md`** for the full step-by-step.

Summary:

1. Generate a shared secret: `openssl rand -hex 32`
2. Add `inbound_email_webhook_secret` to Rails credentials (or set `INBOUND_EMAIL_WEBHOOK_SECRET` in Hatchbox)
3. Update `WEBHOOK_URL` in `cloudflare-worker/wrangler.toml` and deploy the Worker
4. Set `WEBHOOK_SECRET` via `npx wrangler secret put WEBHOOK_SECRET`
5. Change the Cloudflare Email Routing rule to **Send to a Worker** → `email-ingest`

## 11. Deploy

App → **Deploy**. Hatchbox will:

1. Pull the latest commit
2. Run `bundle install` and `npm install` (or `bun install`)
3. Run `assets:precompile` — produces both `public/vite/` (client) and `public/vite-ssr/ssr.js` (SSR)
4. Run `db:prepare` (migrations + seeds on first deploy)
5. Boot the web process + restart the `ssr` and `jobs` processes

## Post-deploy checks

- Visit the site and **view source** on a public page — `<div id="app">` should contain rendered HTML, not be empty. If it's empty, SSR isn't reaching the Node process (check the `ssr` process logs in Hatchbox).
- Visit `/sitemap.xml` (after deploy + sitemap regen) — URLs should use your real domain, not `example.com`. If they don't, `APP_HOST` isn't set.
- Update `public/robots.txt` so the `Sitemap:` line points at your real domain (it ships pointing at `https://example.com/sitemap.xml`).
- Trigger a background job to confirm Solid Queue is processing — check the `jobs` process logs.

- Trigger a password reset and confirm the email sends (Resend dashboard → **Emails**). Check From, Reply-To, and link host match `APP_HOST`.
- Send an email to your inbound address and confirm it appears in `/admin/inbox` (if step 10 is configured).

## Troubleshooting

**Blank page / empty `<div id="app">` in view source.** SSR Node process isn't running or isn't reachable. Check the `ssr` process logs. Confirm `public/vite-ssr/ssr.js` exists in the deployed release (it should, after the `ssrBuildEnabled` fix).

**`ActiveRecord::ConnectionNotEstablished` or queue/cache errors.** The single PostgreSQL DB powers all four (Active Record + Solid Queue/Cache/Cable). Make sure `DATABASE_URL` is set and the DB was provisioned in step 4.

**`Missing secret_key_base` or credentials errors.** `RAILS_MASTER_KEY` not set or doesn't match the encrypted credentials file for that environment. Production needs `config/credentials/production.key` content; staging needs `config/credentials/staging.key`.

**Sitemap shows `example.com` URLs.** `APP_HOST` env var not set.

**Email not sending / Resend errors.** Confirm the Resend domain is **Verified** in the Resend dashboard. Confirm `MAIL_FROM` uses a sender on the verified domain. Confirm `resend_api_key` is in the env-scoped Rails credentials (or set `RESEND_API_KEY`). The Resend dashboard **Emails** log shows delivery status and failure reasons.

**Replies to transactional emails bounce.** Cloudflare Email Routing isn't set up (step 9), or the destination address isn't verified, or the routing rule is missing.

**Inbound emails not appearing in `/admin/inbox`.** Check the Cloudflare Worker logs (`npx wrangler tail email-ingest`). Confirm `INBOUND_EMAIL_WEBHOOK_SECRET` matches `WEBHOOK_SECRET` in the Worker. Confirm the routing rule sends to the Worker, not to an external mailbox.
