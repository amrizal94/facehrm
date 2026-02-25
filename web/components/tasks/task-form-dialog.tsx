'use client'

import { useEffect, useState } from 'react'
import { Plus, X } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useCreateTask, useLabels, useUpdateTask } from '@/hooks/use-tasks'
import { useEmployees } from '@/hooks/use-employees'
import { useProjects } from '@/hooks/use-tasks'
import type { Task } from '@/types/task'

interface TaskFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  task?: Task | null
  defaultProjectId?: number
}

export function TaskFormDialog({ open, onOpenChange, task, defaultProjectId }: TaskFormDialogProps) {
  const [projectId, setProjectId]   = useState<string>('')
  const [title, setTitle]           = useState('')
  const [description, setDescription] = useState('')
  const [status, setStatus]         = useState('todo')
  const [priority, setPriority]     = useState('medium')
  const [deadline, setDeadline]     = useState('')
  const [assignedTo, setAssignedTo] = useState<string>('')
  const [selectedLabels, setSelectedLabels] = useState<number[]>([])
  const [checklistItems, setChecklistItems] = useState<string[]>([])
  const [newChecklistItem, setNewChecklistItem] = useState('')

  const { data: labelsData }    = useLabels()
  const { data: projectsData }  = useProjects({ per_page: 100 })
  const { data: employeesData } = useEmployees({ per_page: 100, status: 'active' })

  const createTask = useCreateTask()
  const updateTask = useUpdateTask()
  const isPending  = createTask.isPending || updateTask.isPending

  const labels    = labelsData ?? []
  const projects  = projectsData?.data ?? []
  const employees = employeesData?.data ?? []

  useEffect(() => {
    if (open) {
      setProjectId(task?.project_id?.toString() ?? defaultProjectId?.toString() ?? '')
      setTitle(task?.title ?? '')
      setDescription(task?.description ?? '')
      setStatus(task?.status ?? 'todo')
      setPriority(task?.priority ?? 'medium')
      setDeadline(task?.deadline ?? '')
      setAssignedTo(task?.assignee?.id?.toString() ?? '')
      setSelectedLabels(task?.labels?.map((l) => l.id) ?? [])
      setChecklistItems([])
      setNewChecklistItem('')
    }
  }, [open, task, defaultProjectId])

  function toggleLabel(id: number) {
    setSelectedLabels((prev) =>
      prev.includes(id) ? prev.filter((l) => l !== id) : [...prev, id]
    )
  }

  function addChecklistItem() {
    const t = newChecklistItem.trim()
    if (!t) return
    setChecklistItems((prev) => [...prev, t])
    setNewChecklistItem('')
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    const data = {
      project_id: parseInt(projectId),
      title: title.trim(),
      description: description.trim() || undefined,
      status:    status    as 'todo' | 'in_progress' | 'done' | 'cancelled',
      priority:  priority  as 'low' | 'medium' | 'high' | 'urgent',
      deadline:  deadline  || undefined,
      assigned_to: assignedTo ? parseInt(assignedTo) : null,
      label_ids:   selectedLabels,
      checklist_items: checklistItems.map((t) => ({ title: t })),
    }
    if (task) {
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { project_id: _p, checklist_items: _c, ...updateData } = data
      updateTask.mutate({ id: task.id, data: updateData }, { onSuccess: () => onOpenChange(false) })
    } else {
      createTask.mutate(data, { onSuccess: () => onOpenChange(false) })
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{task ? 'Edit Task' : 'New Task'}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          {!defaultProjectId && (
            <div className="space-y-1">
              <Label>Project *</Label>
              <Select value={projectId} onValueChange={setProjectId} required>
                <SelectTrigger><SelectValue placeholder="Select project…" /></SelectTrigger>
                <SelectContent>
                  {projects.map((p) => (
                    <SelectItem key={p.id} value={p.id.toString()}>{p.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          <div className="space-y-1">
            <Label htmlFor="task-title">Title *</Label>
            <Input
              id="task-title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              maxLength={500}
              required
            />
          </div>

          <div className="space-y-1">
            <Label htmlFor="task-desc">Description</Label>
            <Textarea
              id="task-desc"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
              maxLength={5000}
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <Label>Status</Label>
              <Select value={status} onValueChange={setStatus}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="todo">To Do</SelectItem>
                  <SelectItem value="in_progress">In Progress</SelectItem>
                  <SelectItem value="done">Done</SelectItem>
                  <SelectItem value="cancelled">Cancelled</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1">
              <Label>Priority</Label>
              <Select value={priority} onValueChange={setPriority}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="low">Low</SelectItem>
                  <SelectItem value="medium">Medium</SelectItem>
                  <SelectItem value="high">High</SelectItem>
                  <SelectItem value="urgent">Urgent</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <Label>Assignee</Label>
              <Select value={assignedTo} onValueChange={setAssignedTo}>
                <SelectTrigger><SelectValue placeholder="Unassigned" /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="">Unassigned</SelectItem>
                  {employees.map((emp) => (
                    <SelectItem key={emp.id} value={emp.id.toString()}>
                      {emp.user.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1">
              <Label htmlFor="task-deadline">Deadline</Label>
              <Input
                id="task-deadline"
                type="date"
                value={deadline}
                onChange={(e) => setDeadline(e.target.value)}
              />
            </div>
          </div>

          {labels.length > 0 && (
            <div className="space-y-1">
              <Label>Labels</Label>
              <div className="flex flex-wrap gap-2">
                {labels.map((label) => {
                  const selected = selectedLabels.includes(label.id)
                  const hex = label.color.replace('#', '')
                  const r = parseInt(hex.substring(0, 2), 16)
                  const g = parseInt(hex.substring(2, 4), 16)
                  const b = parseInt(hex.substring(4, 6), 16)
                  return (
                    <button
                      key={label.id}
                      type="button"
                      onClick={() => toggleLabel(label.id)}
                      className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium border transition-all"
                      style={{
                        backgroundColor: selected ? `rgba(${r},${g},${b},0.15)` : 'transparent',
                        color: label.color,
                        borderColor: label.color,
                        opacity: selected ? 1 : 0.5,
                      }}
                    >
                      <span
                        className="w-2 h-2 rounded-full"
                        style={{ backgroundColor: label.color }}
                      />
                      {label.name}
                    </button>
                  )
                })}
              </div>
            </div>
          )}

          {!task && (
            <div className="space-y-1">
              <Label>Checklist Items</Label>
              {checklistItems.map((item, i) => (
                <div key={i} className="flex items-center gap-2">
                  <span className="flex-1 text-sm">{item}</span>
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="h-6 w-6"
                    onClick={() => setChecklistItems((prev) => prev.filter((_, j) => j !== i))}
                  >
                    <X className="h-3.5 w-3.5" />
                  </Button>
                </div>
              ))}
              <div className="flex gap-2">
                <Input
                  placeholder="Add checklist item…"
                  value={newChecklistItem}
                  onChange={(e) => setNewChecklistItem(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), addChecklistItem())}
                  className="h-8 text-sm"
                />
                <Button type="button" size="sm" variant="outline" onClick={addChecklistItem}>
                  <Plus className="h-4 w-4" />
                </Button>
              </div>
            </div>
          )}

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={isPending || !title.trim() || (!task && !projectId)}>
              {isPending ? 'Saving…' : task ? 'Update' : 'Create'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
