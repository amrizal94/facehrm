'use client'

import Link from 'next/link'
import {
  Users, Clock, CalendarDays, CheckCircle, AlertTriangle,
  UserCheck, Receipt,
} from 'lucide-react'
import { Card } from '@/components/ui/card'
import { DashboardLayout } from '@/components/layout/dashboard-layout'
import { StatCard } from '@/components/layout/stat-card'
import { PendingLeavePanel } from '@/components/dashboard/pending-leave-panel'
import { TodayAttendancePanel } from '@/components/dashboard/today-attendance-panel'
import { useOverview } from '@/hooks/use-reports'
import { useAttendanceSummary } from '@/hooks/use-attendance'

const QUICK_ACTIONS = [
  { label: 'Employees',   href: '/admin/employees',  icon: Users,       color: 'text-blue-600',   bg: 'bg-blue-50' },
  { label: 'Attendance',  href: '/admin/attendance', icon: Clock,       color: 'text-green-600',  bg: 'bg-green-50' },
  { label: 'Leave',       href: '/admin/leave',      icon: CalendarDays, color: 'text-orange-600', bg: 'bg-orange-50' },
  { label: 'Payroll',     href: '/admin/payroll',    icon: Receipt,     color: 'text-purple-600', bg: 'bg-purple-50' },
]

function AttendanceSummaryCard() {
  const { data: summary, isLoading } = useAttendanceSummary()

  const bars = [
    { label: 'Present',  value: summary?.present  ?? 0, color: 'bg-emerald-500', textColor: 'text-emerald-700' },
    { label: 'Late',     value: summary?.late      ?? 0, color: 'bg-amber-500',   textColor: 'text-amber-700' },
    { label: 'On Leave', value: summary?.on_leave  ?? 0, color: 'bg-purple-500',  textColor: 'text-purple-700' },
    { label: 'Absent',   value: summary?.absent    ?? 0, color: 'bg-red-400',     textColor: 'text-red-700' },
  ]

  const total = summary?.total_employees ?? 1

  return (
    <Card className="p-5">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-semibold text-sm">Today&apos;s Attendance</h3>
        <span className="text-xs text-muted-foreground">
          {isLoading ? '…' : `${summary?.total_employees ?? 0} employees`}
        </span>
      </div>

      {isLoading ? (
        <div className="space-y-3">
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="h-4 bg-muted animate-pulse rounded" />
          ))}
        </div>
      ) : (
        <div className="space-y-3">
          {bars.map((b) => {
            const pct = total > 0 ? Math.round((b.value / total) * 100) : 0
            return (
              <div key={b.label} className="space-y-1">
                <div className="flex justify-between text-xs">
                  <span className="text-muted-foreground">{b.label}</span>
                  <span className={`font-semibold ${b.textColor}`}>{b.value} <span className="text-muted-foreground font-normal">({pct}%)</span></span>
                </div>
                <div className="w-full h-2 bg-muted rounded-full overflow-hidden">
                  <div className={`h-full ${b.color} rounded-full transition-all`} style={{ width: `${pct}%` }} />
                </div>
              </div>
            )
          })}
        </div>
      )}

      <div className="mt-4 pt-3 border-t">
        <Link href="/admin/attendance" className="text-xs text-primary hover:underline">
          Manage attendance →
        </Link>
      </div>
    </Card>
  )
}

export default function HRDashboardPage() {
  const { data: overviewData, isLoading } = useOverview()
  const ov = overviewData?.data

  const skeleton = isLoading ? '—' : undefined

  return (
    <DashboardLayout title="HR Dashboard" allowedRoles={['hr', 'admin']}>
      <div className="space-y-6">

        {/* Stat Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            title="Total Employees"
            value={skeleton ?? ov?.total_employees ?? '—'}
            subtitle="Active staff"
            icon={Users}
            iconColor="text-blue-600"
            iconBg="bg-blue-50"
          />
          <StatCard
            title="Present Today"
            value={skeleton ?? ov?.today.present ?? '—'}
            subtitle={ov ? `${ov.today.late} arrived late` : undefined}
            icon={CheckCircle}
            iconColor="text-green-600"
            iconBg="bg-green-50"
          />
          <StatCard
            title="Absent Today"
            value={skeleton ?? ov?.today.absent ?? '—'}
            subtitle="Not checked in"
            icon={AlertTriangle}
            iconColor="text-red-600"
            iconBg="bg-red-50"
          />
          <StatCard
            title="Pending Approvals"
            value={skeleton ?? ov?.pending_leaves ?? '—'}
            subtitle="Leave requests"
            icon={UserCheck}
            iconColor="text-amber-600"
            iconBg="bg-amber-50"
          />
        </div>

        {/* Middle grid: pending leaves + attendance summary */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2">
            <PendingLeavePanel limit={8} />
          </div>
          <AttendanceSummaryCard />
        </div>

        {/* Today's check-ins feed */}
        <TodayAttendancePanel limit={8} />

        {/* Quick actions */}
        <Card className="p-5">
          <h3 className="font-semibold text-sm mb-4">Quick Actions</h3>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {QUICK_ACTIONS.map((a) => (
              <Link
                key={a.href}
                href={a.href}
                className="flex items-center gap-3 p-3 rounded-xl border hover:bg-muted/50 transition-colors"
              >
                <div className={`p-2 rounded-lg ${a.bg} shrink-0`}>
                  <a.icon className={`w-4 h-4 ${a.color}`} />
                </div>
                <span className="text-sm font-medium text-foreground">{a.label}</span>
              </Link>
            ))}
          </div>
        </Card>

      </div>
    </DashboardLayout>
  )
}
