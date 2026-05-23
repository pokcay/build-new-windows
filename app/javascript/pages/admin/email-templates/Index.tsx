import { Head, Link } from "@inertiajs/react"
import { ChevronRight, Mail } from "lucide-react"
import { AdminShell } from "@/components/AdminShell"
import { Badge } from "@/components/ui/badge"

type TemplateRow = {
  id: number
  key: string
  name: string
  description: string | null
  customized: boolean
  updated_at: string
  updater_email: string | null
}

export default function AdminEmailTemplatesIndex({ templates }: { templates: TemplateRow[] }) {
  return (
    <>
      <Head title="Email templates">
        <meta name="description" content="Manage outbound email templates in the admin area." />
        <meta property="og:title" content="Email templates" />
        <meta property="og:description" content="Manage outbound email templates in the admin area." />
      </Head>
      <AdminShell>
        <div className="border-b border-hairline pb-6">
          <h1>Email templates</h1>
          <p className="mt-1">
            Edit and preview every transactional email the app sends. Changes take effect immediately — no deploy needed.
          </p>
        </div>

        <ul className="mt-6 divide-y divide-hairline overflow-hidden rounded-md border border-hairline bg-page">
          {templates.map((template) => (
            <li key={template.id}>
              <Link
                href={`/admin/email-templates/${template.id}`}
                className="flex items-center gap-3 px-4 py-4 no-underline hover:bg-surface"
              >
                <Mail className="h-4 w-4 shrink-0 text-ink-muted" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-ink-display">{template.name}</span>
                    <Badge tone={template.customized ? "accent" : "neutral"}>
                      {template.customized ? "Customized" : "Default"}
                    </Badge>
                  </div>
                  {template.description && (
                    <p className="mt-0.5 truncate text-xs text-ink-muted">{template.description}</p>
                  )}
                  <p className="mt-0.5 text-xs text-ink-muted">
                    Updated {relativeTime(template.updated_at)}
                    {template.updater_email ? ` by ${template.updater_email}` : ""}
                  </p>
                </div>
                <ChevronRight className="h-4 w-4 shrink-0 text-ink-muted" />
              </Link>
            </li>
          ))}
        </ul>
      </AdminShell>
    </>
  )
}

function relativeTime(iso: string) {
  const diff = Date.now() - new Date(iso).getTime()
  const minutes = Math.floor(diff / 60_000)
  if (minutes < 1) return "just now"
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  if (days < 30) return `${days}d ago`
  return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" })
}
