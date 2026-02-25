'use client'

import { useState } from 'react'
import { Plus, Trash2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { useAddChecklistItem, useDeleteChecklistItem, useToggleChecklistItem } from '@/hooks/use-tasks'
import type { ChecklistItem } from '@/types/task'

interface ChecklistPanelProps {
  taskId: number
  items: ChecklistItem[]
  isAdmin?: boolean
}

export function ChecklistPanel({ taskId, items, isAdmin = false }: ChecklistPanelProps) {
  const [newTitle, setNewTitle] = useState('')
  const addItem    = useAddChecklistItem(taskId)
  const toggleItem = useToggleChecklistItem()
  const deleteItem = useDeleteChecklistItem(taskId)

  const done  = items.filter((i) => i.is_done).length
  const total = items.length
  const pct   = total > 0 ? Math.round((done / total) * 100) : 0

  function handleAdd() {
    const title = newTitle.trim()
    if (!title) return
    addItem.mutate(title, { onSuccess: () => setNewTitle('') })
  }

  return (
    <div className="space-y-3">
      {total > 0 && (
        <div className="flex items-center gap-2">
          <div className="flex-1 h-2 bg-slate-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-emerald-500 rounded-full transition-all"
              style={{ width: `${pct}%` }}
            />
          </div>
          <span className="text-xs text-muted-foreground w-10 text-right">{pct}%</span>
        </div>
      )}

      <ul className="space-y-1">
        {items.map((item) => (
          <li key={item.id} className="flex items-center gap-2 group">
            <input
              type="checkbox"
              id={`item-${item.id}`}
              checked={item.is_done}
              onChange={() => toggleItem.mutate({ taskId, itemId: item.id })}
              className="h-4 w-4 rounded border-gray-300 text-primary cursor-pointer"
            />
            <label
              htmlFor={`item-${item.id}`}
              className={`flex-1 text-sm cursor-pointer ${item.is_done ? 'line-through text-muted-foreground' : ''}`}
            >
              {item.title}
            </label>
            {isAdmin && (
              <Button
                variant="ghost"
                size="icon"
                className="h-6 w-6 opacity-0 group-hover:opacity-100 transition-opacity"
                onClick={() => deleteItem.mutate(item.id)}
              >
                <Trash2 className="h-3.5 w-3.5 text-destructive" />
              </Button>
            )}
          </li>
        ))}
      </ul>

      {isAdmin && (
        <div className="flex gap-2">
          <Input
            placeholder="Add item…"
            value={newTitle}
            onChange={(e) => setNewTitle(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleAdd()}
            className="h-8 text-sm"
          />
          <Button size="sm" variant="outline" onClick={handleAdd} disabled={addItem.isPending}>
            <Plus className="h-4 w-4" />
          </Button>
        </div>
      )}
    </div>
  )
}
