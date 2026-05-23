/**
 * Inbound Email Ingest Worker
 *
 * Receives email from Cloudflare Email Routing, parses it with postal-mime,
 * and forwards a structured JSON payload to the Rails webhook endpoint.
 *
 * Required environment variables (set via Wrangler secrets):
 *   WEBHOOK_SECRET — shared secret verified by the Rails webhook controller
 *
 * Required environment variables (set in wrangler.toml [vars]):
 *   WEBHOOK_URL — full URL of the webhook endpoint, e.g.
 *                 https://yourdomain.com/webhooks/inbound_email
 */
import PostalMime from "postal-mime";

export default {
  async email(message, env, ctx) {
    const parser = new PostalMime();
    const rawBytes = await new Response(message.raw).arrayBuffer();
    const parsed = await parser.parse(rawBytes);

    const payload = {
      from: message.from,
      to: message.to,
      subject: parsed.subject ?? message.headers.get("Subject") ?? null,
      reply_to: parsed.replyTo?.[0]?.address ?? null,
      body_html: parsed.html ?? null,
      body_text: parsed.text ?? null,
      received_at: new Date().toISOString(),
    };

    const response = await fetch(env.WEBHOOK_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Webhook-Secret": env.WEBHOOK_SECRET,
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new Error(
        `Webhook returned ${response.status}: ${await response.text()}`,
      );
    }
  },
};
