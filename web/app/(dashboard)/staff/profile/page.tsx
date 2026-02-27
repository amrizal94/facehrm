'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Loader2, CheckCircle2 } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Separator } from '@/components/ui/separator'
import { DashboardLayout } from '@/components/layout/dashboard-layout'
import { useUpdateProfile } from '@/hooks/use-settings'
import { useAuthStore } from '@/store/auth-store'

// ─── Schemas ──────────────────────────────────────────────────────────────────

const profileSchema = z.object({
  name:  z.string().min(1, 'Name is required'),
  phone: z.string().optional(),
})

const passwordSchema = z.object({
  current_password:      z.string().min(1, 'Current password is required'),
  password:              z.string().min(8, 'New password must be at least 8 characters'),
  password_confirmation: z.string().min(1, 'Please confirm password'),
}).refine(d => d.password === d.password_confirmation, {
  message: 'Passwords do not match',
  path: ['password_confirmation'],
})

type ProfileForm  = z.infer<typeof profileSchema>
type PasswordForm = z.infer<typeof passwordSchema>

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function StaffProfilePage() {
  const user = useAuthStore(s => s.user)
  const { mutate: updateProfile, isPending, isSuccess } = useUpdateProfile()

  const profileForm = useForm<ProfileForm>({
    resolver: zodResolver(profileSchema),
    defaultValues: { name: user?.name ?? '', phone: user?.phone ?? '' },
  })

  const pwForm = useForm<PasswordForm>({ resolver: zodResolver(passwordSchema) })

  function onProfileSubmit(data: ProfileForm) {
    updateProfile(data, {
      onSuccess: () => toast.success('Profile updated.'),
      onError:   () => toast.error('Failed to update profile.'),
    })
  }

  function onPasswordSubmit(data: PasswordForm) {
    updateProfile(data, {
      onSuccess: () => { toast.success('Password changed.'); pwForm.reset() },
      onError: (err: unknown) => {
        const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message
        toast.error(msg ?? 'Failed to change password.')
      },
    })
  }

  const initial = (user?.name ?? 'U').charAt(0).toUpperCase()

  return (
    <DashboardLayout title="My Profile">
      <div className="max-w-lg space-y-8">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">My Profile</h1>
          <p className="text-muted-foreground text-sm mt-0.5">Manage your personal information and password</p>
        </div>

        {/* Avatar */}
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-indigo-600 flex items-center justify-center text-white text-2xl font-bold shrink-0">
            {initial}
          </div>
          <div>
            <p className="font-semibold text-lg">{user?.name}</p>
            <p className="text-sm text-muted-foreground capitalize">{user?.role}</p>
          </div>
        </div>

        <Separator />

        {/* Personal Info */}
        <div>
          <h3 className="font-semibold mb-4">Personal Information</h3>
          <form onSubmit={profileForm.handleSubmit(onProfileSubmit)} className="space-y-4">
            <div className="space-y-1.5">
              <Label>Email</Label>
              <Input value={user?.email ?? ''} disabled className="bg-muted/50" />
              <p className="text-xs text-muted-foreground">Email cannot be changed.</p>
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="name">Full Name</Label>
              <Input id="name" {...profileForm.register('name')} />
              {profileForm.formState.errors.name && (
                <p className="text-xs text-red-500">{profileForm.formState.errors.name.message}</p>
              )}
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="phone">Phone</Label>
              <Input id="phone" {...profileForm.register('phone')} placeholder="+62..." />
            </div>
            <Button type="submit" disabled={isPending}>
              {isPending && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
              {isSuccess ? <><CheckCircle2 className="w-4 h-4 mr-2" />Saved</> : 'Save Profile'}
            </Button>
          </form>
        </div>

        <Separator />

        {/* Change Password */}
        <div>
          <h3 className="font-semibold mb-4">Change Password</h3>
          <form onSubmit={pwForm.handleSubmit(onPasswordSubmit)} className="space-y-4">
            <div className="space-y-1.5">
              <Label htmlFor="current_password">Current Password</Label>
              <Input id="current_password" type="password" {...pwForm.register('current_password')} />
              {pwForm.formState.errors.current_password && (
                <p className="text-xs text-red-500">{pwForm.formState.errors.current_password.message}</p>
              )}
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="password">New Password</Label>
              <Input id="password" type="password" {...pwForm.register('password')} />
              {pwForm.formState.errors.password && (
                <p className="text-xs text-red-500">{pwForm.formState.errors.password.message}</p>
              )}
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="password_confirmation">Confirm New Password</Label>
              <Input id="password_confirmation" type="password" {...pwForm.register('password_confirmation')} />
              {pwForm.formState.errors.password_confirmation && (
                <p className="text-xs text-red-500">{pwForm.formState.errors.password_confirmation.message}</p>
              )}
            </div>
            <Button type="submit" variant="outline" disabled={isPending}>
              {isPending && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
              Change Password
            </Button>
          </form>
        </div>
      </div>
    </DashboardLayout>
  )
}
