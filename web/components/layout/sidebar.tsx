'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
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
} from 'lucide-react'

interface NavItem {
  label: string
  href: string
  icon: LucideIcon
  roles: string[]
}

const NAV_ITEMS: NavItem[] = [
  { label: 'Dashboard', href: '/admin', icon: LayoutDashboard, roles: ['admin'] },
  { label: 'Dashboard', href: '/hr', icon: LayoutDashboard, roles: ['hr'] },
  { label: 'Dashboard', href: '/staff', icon: LayoutDashboard, roles: ['staff'] },
  { label: 'Employees', href: '/admin/employees', icon: Users, roles: ['admin', 'hr'] },
  { label: 'Attendance', href: '/admin/attendance', icon: Clock, roles: ['admin', 'hr'] },
  { label: 'My Attendance', href: '/staff/attendance', icon: Clock, roles: ['staff'] },
  { label: 'Leave', href: '/admin/leave', icon: CalendarDays, roles: ['admin', 'hr'] },
  { label: 'My Leave', href: '/staff/leave', icon: CalendarDays, roles: ['staff'] },
  { label: 'Payroll', href: '/admin/payroll', icon: Receipt, roles: ['admin', 'hr'] },
  { label: 'My Payslip', href: '/staff/payslip', icon: Receipt, roles: ['staff'] },
  { label: 'Face Data', href: '/admin/face', icon: ScanFace, roles: ['admin', 'hr'] },
  { label: 'Reports', href: '/admin/reports', icon: BarChart3, roles: ['admin'] },
  { label: 'Settings', href: '/admin/settings', icon: Settings, roles: ['admin'] },
]

export function Sidebar() {
  const pathname = usePathname()
  const user = useAuthStore((s) => s.user)
  const role = user?.role ?? 'staff'

  const filteredItems = NAV_ITEMS.filter((item) => item.roles.includes(role))

  return (
    <aside className="flex flex-col w-64 min-h-screen bg-slate-900 text-slate-100">
      {/* Logo */}
      <div className="flex items-center gap-3 px-6 py-5 border-b border-slate-700">
        <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
          <ScanFace className="w-5 h-5 text-white" />
        </div>
        <span className="text-lg font-bold tracking-tight">FaceHRM</span>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 py-4 space-y-0.5">
        {filteredItems.map((item) => {
          const isActive = pathname === item.href
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
            <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white text-sm font-bold">
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
  )
}
