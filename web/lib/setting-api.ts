import { api } from './api'
import type { AllSettings } from '@/types/setting'

export async function fetchSettings(): Promise<{ success: boolean; data: AllSettings }> {
  const res = await api.get('/settings')
  return res.data
}

export async function updateSettings(data: Record<string, Record<string, string | number>>): Promise<{ success: boolean; message: string }> {
  const res = await api.put('/settings', data)
  return res.data
}

export async function updateProfile(data: {
  name?: string
  phone?: string
  current_password?: string
  password?: string
  password_confirmation?: string
}): Promise<{ success: boolean; message: string; data?: { user: { id: number; name: string; email: string; role: string } } }> {
  const res = await api.put('/auth/profile', data)
  return res.data
}
