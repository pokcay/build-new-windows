import * as React from "react"
import { Head, Link, router, usePage } from "@inertiajs/react"
import { AdminShell } from "@/components/AdminShell"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { Select } from "@/components/ui/select"
import type { PageProps } from "@/types/inertia"

type EmailSummary = {
  id: number
  from: string
  to: string
  subject: string | null
  received_at: string
  read: boolean
  archived: boolean
}

type Props = {
  emails: EmailSummary[]
  total: number
  page: number
  per_page: number
  tab: string
  recipient: string | null
  recipients: string[]
}

type Tab = "all" | "unread" | "archived"

export default function AdminInboxIndex() {
  const { props } = usePage<PageProps<Props>>()
  const { emails, total, page, per_page, tab, recipient, recipients } = props

  const [selectedIds, setSelectedIds] = React.useState<Set<number>>(new Set())
  const totalPages = Math.ceil(total / per_page)
  const hasSelected = selectedIds.size > 0

  function navigate(overrides: Record<string, string | number | null>) {
    const params: Record<string, string | number> = {}
    if (tab !== "all") params.tab = tab
    if (recipient) params.recipient = recipient
    if (page > 1) params.page = page
    Object.entries(overrides).forEach(([k, v]) => {
      if (v !== null && v !== undefined && v !== "") params[k] = v
      else delete params[k]
    })
    setSelectedIds(new Set())
    router.get("/admin/inbox", params as Record<string, string>, { preserveScroll: false })
  }

  function setTab(t: Tab) {
    navigate({ tab: t === "all" ? null : t, page: null })
  }

  function setRecipient(r: string) {
    navigate({ recipient: r || null, page: null })
  }

  function toggleSelect(id: number) {
    setSelectedIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  function toggleSelectAll() {
    if (selectedIds.size === emails.length) {
      setSelectedIds(new Set())
    } else {
      setSelectedIds(new Set(emails.map((e) => e.id)))
    }
  }

  function bulkAction(actionType: string) {
    router.patch(
      "/admin/inbox/bulk_update",
      { ids: Array.from(selectedIds), action_type: actionType },
      { onFinish: () => setSelectedIds(new Set()) },
    )
  }

  const notice = props.flash?.notice
  const alert = props.flash?.alert

  return (
    <>
      <Head title="Inbox">
        <meta name="description" content="Admin inbox for inbound emails." />
        <meta property="og:title" content="Inbox" />
        <meta property="og:description" content="Admin inbox for inbound emails." />
      </Head>
      <AdminShell>
        <div className="border-b border-hairline pb-6">
          <div className="flex items-end justify-between gap-4">
            <div>
              <h1>Inbox</h1>
              <p className="mt-1">{total} {total === 1 ? "email" : "emails"} in this view.</p>
            </div>
            {recipients.length > 1 && (
              <Select
                value={recipient ?? ""}
                onChange={(e) => setRecipient(e.target.value)}
                className="w-52"
              >
                <option value="">All recipients</option>
                {recipients.map((r) => (
                  <option key={r} value={r}>{r}</option>
                ))}
              </Select>
            )}
          </div>
        </div>

        {notice && <p className="mt-4 text-sm text-accent">{notice}</p>}
        {alert && <p className="mt-4 text-sm text-danger-display">{alert}</p>}

        <div className="mt-6 flex gap-1 border-b border-hairline">
          {(["all", "unread", "archived"] as Tab[]).map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => setTab(t)}
              className={[
                "px-3 py-2 text-sm font-medium -mb-px border-b-2 transition-colors capitalize",
                tab === t
                  ? "border-accent text-accent"
                  : "border-transparent text-ink-muted hover:text-ink-body",
              ].join(" ")}
            >
              {t}
            </button>
          ))}
        </div>

        {hasSelected && (
          <div className="mt-3 flex flex-wrap items-center gap-2 rounded-md border border-hairline bg-surface px-3 py-2">
            <span className="text-xs text-ink-muted">{selectedIds.size} selected</span>
            <Button variant="ghost" size="sm" type="button" onClick={() => bulkAction("mark_read")}>
              Mark read
            </Button>
            <Button variant="ghost" size="sm" type="button" onClick={() => bulkAction("mark_unread")}>
              Mark unread
            </Button>
            {tab === "archived" ? (
              <Button variant="ghost" size="sm" type="button" onClick={() => bulkAction("restore")}>
                Restore
              </Button>
            ) : (
              <Button variant="ghost" size="sm" type="button" onClick={() => bulkAction("archive")}>
                Archive
              </Button>
            )}
            <Button
              variant="ghost"
              size="sm"
              type="button"
              className="ml-auto"
              onClick={() => setSelectedIds(new Set())}
            >
              Clear selection
            </Button>
          </div>
        )}

        {emails.length === 0 ? (
          <p className="mt-10 text-center text-sm text-ink-muted">No emails in this view.</p>
        ) : (
          <div className="mt-3 overflow-hidden rounded-md border border-hairline bg-page">
            <div className="flex items-center gap-3 border-b border-hairline px-4 py-2">
              <Checkbox
                checked={selectedIds.size === emails.length && emails.length > 0}
                onChange={toggleSelectAll}
                aria-label="Select all"
              />
              <span className="text-xs text-ink-muted">Select all</span>
            </div>

            <ul className="divide-y divide-hairline">
              {emails.map((email) => (
                <li key={email.id} className={email.read ? "bg-page" : "bg-surface/40"}>
                  <div className="flex items-center gap-3 px-4 py-3">
                    <Checkbox
                      checked={selectedIds.has(email.id)}
                      onChange={() => toggleSelect(email.id)}
                      aria-label={`Select email from ${email.from}`}
                    />
                    <span
                      className={[
                        "h-2 w-2 shrink-0 rounded-full",
                        email.read ? "bg-transparent" : "bg-accent",
                      ].join(" ")}
                      aria-hidden
                    />
                    <Link
                      href={`/admin/inbox/${email.id}`}
                      className="min-w-0 flex-1 no-underline"
                    >
                      <div className="flex items-baseline gap-2">
                        <span
                          className={[
                            "truncate text-sm",
                            email.read
                              ? "text-ink-muted"
                              : "font-semibold text-ink-display",
                          ].join(" ")}
                        >
                          {email.from}
                        </span>
                        <span className="shrink-0 text-xs text-ink-muted">
                          → {email.to}
                        </span>
                        <span className="ml-auto shrink-0 text-xs text-ink-muted">
                          {relativeTime(email.received_at)}
                        </span>
                      </div>
                      <p
                        className={[
                          "mt-0.5 truncate text-sm",
                          email.read ? "text-ink-muted" : "text-ink-body",
                        ].join(" ")}
                      >
                        {email.subject || "(no subject)"}
                      </p>
                    </Link>
                  </div>
                </li>
              ))}
            </ul>
          </div>
        )}

        {totalPages > 1 && (
          <div className="mt-6 flex items-center justify-between">
            <Button
              variant="secondary"
              size="sm"
              type="button"
              disabled={page <= 1}
              onClick={() => navigate({ page: page - 1 })}
            >
              Previous
            </Button>
            <span className="text-sm text-ink-muted">
              Page {page} of {totalPages}
            </span>
            <Button
              variant="secondary"
              size="sm"
              type="button"
              disabled={page >= totalPages}
              onClick={() => navigate({ page: page + 1 })}
            >
              Next
            </Button>
          </div>
        )}
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
  return new Date(iso).toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
  })
}
