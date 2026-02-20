import { api as apiClient } from './api'
import type { FaceAttendanceResult, FaceEnrollmentMeta, FaceEnrollmentStatus, IdentifyResult } from '@/types/face'

export interface FaceListResponse {
  success: boolean
  data: FaceEnrollmentStatus[]
  meta: FaceEnrollmentMeta
}

export async function fetchFaceEnrollments(params?: {
  page?: number
  per_page?: number
  search?: string
  enrolled?: boolean
}): Promise<FaceListResponse> {
  const query = new URLSearchParams()
  if (params?.page)       query.set('page', String(params.page))
  if (params?.per_page)   query.set('per_page', String(params.per_page))
  if (params?.search)     query.set('search', params.search)
  if (params?.enrolled !== undefined) query.set('enrolled', String(params.enrolled))

  const res = await apiClient.get<FaceListResponse>(`/face?${query}`)
  return res.data
}

export async function enrollFace(data: {
  employee_id: number
  descriptor: number[]
  snapshot?: string | null
}): Promise<{ success: boolean; message: string; data: FaceEnrollmentStatus }> {
  const res = await apiClient.post('/face/enroll', data)
  return res.data
}

export async function deleteFaceData(faceDataId: number): Promise<{ success: boolean; message: string }> {
  const res = await apiClient.delete(`/face/${faceDataId}`)
  return res.data
}

export async function identifyFace(descriptor: number[]): Promise<{ success: boolean; data?: IdentifyResult; message?: string }> {
  const res = await apiClient.post('/face/identify', { descriptor })
  return res.data
}

export async function faceAttendance(data: {
  descriptor: number[]
  action: 'check_in' | 'check_out'
}): Promise<FaceAttendanceResult> {
  const res = await apiClient.post('/face/attendance', data)
  return res.data
}
