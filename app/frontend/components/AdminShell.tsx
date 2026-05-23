import * as React from "react"
import { Home, Inbox, Mail, Palette, Users } from "lucide-react"
import { usePage } from "@inertiajs/react"
import { MainNav, type NavItemDef } from "@/components/MainNav"
import type { PageProps } from "@/types/inertia"

export function AdminShell({ children }: { children: React.ReactNode }) {
  const { props } = usePage<PageProps>()
  const unreadCount = props.admin_inbox_unread_count ?? 0

  const adminNavItems: NavItemDef[] = [
    {
      href: "/",
      icon: Home,
      label: "App Home",
      match: () => false,
    },
    {
      href: "/admin/users",
      icon: Users,
      label: "Users",
      match: (url) => url.startsWith("/admin/users"),
    },
    {
      href: "/admin/inbox",
      icon: Inbox,
      label: "Inbox",
      match: (url) => url.startsWith("/admin/inbox"),
      badge: unreadCount > 0 ? String(unreadCount) : undefined,
    },
    {
      href: "/admin/email-templates",
      icon: Mail,
      label: "Email templates",
      match: (url) => url.startsWith("/admin/email-templates"),
    },
    {
      href: "/admin/design-system",
      icon: Palette,
      label: "Design System",
      match: (url) => url.startsWith("/admin/design-system"),
    },
  ]

  return (
    <div className="flex min-h-screen bg-page text-ink-body">
      <MainNav items={adminNavItems} brandHref="/admin/users" />
      <main className="min-w-0 flex-1 px-6 py-8 sm:px-10">
        <div className="mx-auto max-w-4xl">{children}</div>
      </main>
    </div>
  )
}
