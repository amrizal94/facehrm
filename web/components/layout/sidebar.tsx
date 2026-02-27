'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useEffect } from 'react'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/store/auth-store'
import type { LucideIcon } from 'lucide-react'
import {
  LayoutDashboard,
  Users,
  Clock,
  CalendarDays,
  Receipt,
  Settings,
  ScanFace,
  BarChart3,
  Timer,
  FolderKanban,
  CheckSquare,
  Bell,
  AlarmClock,
  UserCircle,
} from 'lucide-react'

interface NavItem {
  label: string
  href: string
  icon: LucideIcon
  roles: string[]
}

const NAV_ITEMS: NavItem[] = [
  { label: 'Dashboard',   href: '/admin',            icon: LayoutDashboard, roles: ['admin'] },
  { label: 'Dashboard',   href: '/hr',               icon: LayoutDashboard, roles: ['hr'] },
  { label: 'Dashboard',   href: '/staff',             icon: LayoutDashboard, roles: ['staff'] },
  { label: 'Employees',   href: '/admin/employees',  icon: Users,           roles: ['admin', 'hr'] },
  { label: 'Attendance',  href: '/admin/attendance', icon: Clock,           roles: ['admin', 'hr'] },
  { label: 'My Attendance', href: '/staff/attendance', icon: Clock,         roles: ['staff'] },
  { label: 'Leave',       href: '/admin/leave',      icon: CalendarDays,    roles: ['admin', 'hr'] },
  { label: 'My Leave',    href: '/staff/leave',      icon: CalendarDays,    roles: ['staff'] },
  { label: 'Overtime',    href: '/admin/overtime',   icon: Timer,           roles: ['admin', 'hr'] },
  { label: 'My Overtime', href: '/staff/overtime',   icon: Timer,           roles: ['staff'] },
  { label: 'Holidays',    href: '/admin/holidays',   icon: CalendarDays,    roles: ['admin', 'hr'] },
  { label: 'Payroll',     href: '/admin/payroll',    icon: Receipt,         roles: ['admin', 'hr'] },
  { label: 'My Payslip',  href: '/staff/payslip',    icon: Receipt,         roles: ['staff'] },
  { label: 'Face Data',   href: '/admin/face',       icon: ScanFace,        roles: ['admin', 'hr'] },
  { label: 'Reports',     href: '/admin/reports',    icon: BarChart3,       roles: ['admin', 'hr'] },
  { label: 'Projects',    href: '/admin/projects',   icon: FolderKanban,    roles: ['admin', 'hr'] },
  { label: 'Settings',    href: '/admin/settings',   icon: Settings,        roles: ['admin'] },
  { label: 'My Tasks',      href: '/staff/tasks',      icon: CheckSquare,     roles: ['staff'] },
  { label: 'My Shift',     href: '/staff/shift',      icon: AlarmClock,      roles: ['staff'] },
  { label: 'Holidays',     href: '/staff/holidays',   icon: CalendarDays,    roles: ['staff'] },
  { label: 'My Profile',   href: '/staff/profile',    icon: UserCircle,      roles: ['staff', 'hr', 'admin'] },
  { label: 'Notifications', href: '/notifications',   icon: Bell,            roles: ['admin', 'hr', 'staff'] },
]

interface SidebarProps {
  isOpen?: boolean
  onClose?: () => void
}

export function Sidebar({ isOpen, onClose }: SidebarProps) {
  const pathname = usePathname()
  const user = useAuthStore((s) => s.user)
  const role = user?.role ?? 'staff'

  const filteredItems = NAV_ITEMS.filter((item) => item.roles.includes(role))

  // Close sidebar on navigation (mobile)
  useEffect(() => {
    onClose?.()
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pathname])

  return (
    <>
      {/* Backdrop overlay — mobile only */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={onClose}
          aria-hidden="true"
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-50 flex flex-col w-64 bg-slate-900 text-slate-100 transition-transform duration-300 ease-in-out',
          'lg:static lg:translate-x-0 lg:z-auto lg:shrink-0',
          isOpen ? 'translate-x-0' : '-translate-x-full'
        )}
      >
        {/* Logo */}
        <div className="flex items-center gap-3 px-6 py-5 border-b border-slate-700">
          <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
            <ScanFace className="w-5 h-5 text-white" />
          </div>
          <span className="text-lg font-bold tracking-tight">FaceHRM</span>
        </div>

        {/* Nav */}
        <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">
          {filteredItems.map((item) => {
            // Dashboard items: exact match. Others: startsWith so sub-pages stay highlighted.
          const isActive = item.href === '/admin' || item.href === '/hr' || item.href === '/staff'
            ? pathname === item.href
            : pathname === item.href || pathname.startsWith(item.href + '/')
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                  isActive
                    ? 'bg-primary text-white'
                    : 'text-slate-400 hover:text-white hover:bg-slate-800'
                )}
              >
                <item.icon className="w-4 h-4 shrink-0" />
                {item.label}
              </Link>
            )
          })}
        </nav>

        {/* User info */}
        {user && (
          <div className="px-4 py-4 border-t border-slate-700">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white text-sm font-bold shrink-0">
                {user.name.charAt(0).toUpperCase()}
              </div>
              <div className="overflow-hidden">
                <p className="text-sm font-medium text-slate-100 truncate">{user.name}</p>
                <p className="text-xs text-slate-400 uppercase">{user.role}</p>
              </div>
            </div>
          </div>
        )}
      </aside>
    </>
  )
}
