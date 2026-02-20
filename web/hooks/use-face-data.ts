import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { deleteFaceData, enrollFace, faceAttendance, fetchFaceEnrollments, identifyFace } from '@/lib/face-data-api'

export function useFaceEnrollments(params?: { page?: number; search?: string; enrolled?: boolean }) {
  return useQuery({
    queryKey: ['face-enrollments', params],
    queryFn: () => fetchFaceEnrollments({ per_page: 20, ...params }),
  })
}

export function useEnrollFace() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: enrollFace,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['face-enrollments'] }),
  })
}

export function useDeleteFaceData() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: deleteFaceData,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['face-enrollments'] }),
  })
}

export function useIdentifyFace() {
  return useMutation({ mutationFn: identifyFace })
}

export function useFaceAttendance() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: faceAttendance,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['attendance-today'] })
      qc.invalidateQueries({ queryKey: ['attendance-my'] })
    },
  })
}
