'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { Sidebar } from './sidebar'
import { Header } from './header'
import { useMe } from '@/hooks/use-auth'
import { Loader2 } from 'lucide-react'
import type { Role } from '@/types/auth'

interface DashboardLayoutProps {
  children: React.ReactNode
  title: string
  allowedRoles?: Role[]
}

export function DashboardLayout({ children, title, allowedRoles }: DashboardLayoutProps) {
  const router = useRouter()
  const { data: user, isLoading, isError } = useMe()

  useEffect(() => {
    if (isError) router.push('/login')
  }, [isError, router])

  useEffect(() => {
    if (user && allowedRoles && !allowedRoles.includes(user.role)) {
      router.push('/unauthorized')
    }
  }, [user, allowedRoles, router])

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50">
        <div className="text-center space-y-3">
          <Loader2 className="h-8 w-8 animate-spin text-primary mx-auto" />
          <p className="text-sm text-slate-500">Loading...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Header title={title} />
        <main className="flex-1 p-6 overflow-auto">{children}</main>
      </div>
    </div>
  )
}
