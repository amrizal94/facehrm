'use client'

import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Button } from '@/components/ui/button'
import { Printer } from 'lucide-react'
import type { PayrollRecord } from '@/types/payroll'

interface Props {
  record: PayrollRecord | null
  onOpenChange: (open: boolean) => void
}

const IDR = (v: number) =>
  new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(v)

function printPayslip(record: PayrollRecord) {
  const emp = record.employee
  const f = IDR
  const row = (label: string, value: string, bold = false, sep = false) =>
    `${sep ? '<tr><td colspan="2"><hr style="margin:4px 0;border-color:#e2e8f0"></td></tr>' : ''}
    <tr style="${bold ? 'font-weight:600' : ''}">
      <td style="padding:4px 16px 4px 0;color:#64748b;width:180px;font-size:13px">${label}</td>
      <td style="padding:4px 0;text-align:right;font-size:13px">${value}</td>
    </tr>`

  const html = `<!DOCTYPE html><html lang="id"><head><meta charset="UTF-8">
<title>Payslip — ${record.period_label}</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:system-ui,sans-serif;padding:32px;color:#1e293b}
.company{font-size:18px;font-weight:700;color:#0f172a;border-bottom:2px solid #0f172a;padding-bottom:8px;margin-bottom:12px}
h1{font-size:18px;font-weight:700;margin-bottom:2px}
.sub{color:#64748b;font-size:12px;margin-bottom:16px}
.emp-name{font-weight:600;font-size:14px;margin-bottom:2px}
.emp-detail{font-size:12px;color:#475569;margin-bottom:1px}
.emp-mono{font-family:monospace;font-size:11px;color:#94a3b8}
.sect{font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.05em;color:#94a3b8;margin:16px 0 8px}
.att{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin-bottom:4px}
.att-box{background:#f8fafc;border:1px solid #e2e8f0;border-radius:8px;text-align:center;padding:8px}
.att-num{font-size:18px;font-weight:700}
.att-lbl{font-size:10px;color:#64748b;margin-top:2px}
table{width:100%;border-collapse:collapse}
.net{margin-top:12px;background:#eff6ff;border:1px solid #bfdbfe;border-radius:8px;padding:12px 16px;display:flex;justify-content:space-between;align-items:center}
.net-lbl{font-size:13px;font-weight:600}
.net-amt{font-size:20px;font-weight:700;color:#2563eb}
.foot{margin-top:24px;display:flex;justify-content:space-between;align-items:flex-end;font-size:11px;color:#64748b;border-top:1px solid #e2e8f0;padding-top:12px}
.sign{text-align:center;width:120px}
.sign-line{border-top:1px solid #1e293b;margin-top:44px;padding-top:4px;font-size:11px}
@media print{body{padding:16px}}
</style></head><body>
<div class="company">FaceHRM</div>
<h1>Payslip — ${record.period_label}</h1>
<p class="sub">Dibuat ${new Date().toLocaleDateString('id-ID',{day:'numeric',month:'long',year:'numeric'})}</p>
${emp ? `<p class="emp-name">${emp.user.name}</p>
<p class="emp-detail">${emp.position}${emp.department ? ' · ' + emp.department.name : ''}</p>
<p class="emp-mono">${emp.employee_number}</p>` : ''}
<p class="sect">Attendance</p>
<div class="att">
  <div class="att-box"><div class="att-num">${record.working_days}</div><div class="att-lbl">Working</div></div>
  <div class="att-box"><div class="att-num">${record.present_days}</div><div class="att-lbl">Present</div></div>
  <div class="att-box"><div class="att-num">${record.leave_days}</div><div class="att-lbl">Leave</div></div>
  <div class="att-box"><div class="att-num">${record.absent_days}</div><div class="att-lbl">Absent</div></div>
</div>
<p class="sect">Salary Breakdown</p>
<table><tbody>
  ${row('Basic Salary', f(record.basic_salary))}
  ${row('Allowances', f(record.allowances))}
  ${row('Overtime', f(record.overtime_pay))}
  ${row('Gross Salary', f(record.gross_salary), true, true)}
  ${row('Absent Deduction', '– ' + f(record.absent_deduction))}
  ${row('Other Deductions', '– ' + f(record.other_deductions))}
  ${row('PPh21 (Tax 5%)', '– ' + f(record.tax_deduction))}
  ${row('BPJS (3%)', '– ' + f(record.bpjs_deduction))}
  ${row('Total Deductions', '– ' + f(record.total_deductions), true, true)}
</tbody></table>
<div class="net"><span class="net-lbl">Net Salary</span><span class="net-amt">${f(record.net_salary)}</span></div>
<div class="foot">
  <div>
    <p>Status: <strong style="text-transform:capitalize">${record.status}</strong></p>
    ${record.paid_at ? `<p>Dibayar: ${new Date(record.paid_at).toLocaleDateString('id-ID',{day:'numeric',month:'long',year:'numeric'})}</p>` : ''}
    ${record.notes ? `<p>Catatan: ${record.notes}</p>` : ''}
  </div>
  <div class="sign"><div class="sign-line">HRD / Authorized</div></div>
</div>
</body></html>`

  const win = window.open('', '_blank', 'width=720,height=920')
  if (!win) { alert('Popup diblokir browser. Izinkan popup untuk mencetak payslip.'); return }
  win.document.write(html)
  win.document.close()
  // Tunggu load sebelum print agar stylesheet diterapkan
  win.addEventListener('load', () => win.print())
}

function Row({ label, value, bold, separator }: { label: string; value: string; bold?: boolean; separator?: boolean }) {
  return (
    <>
      {separator && <tr><td colSpan={2}><div className="border-t my-1" /></td></tr>}
      <tr className={bold ? 'font-semibold' : ''}>
        <td className="py-1 pr-4 text-muted-foreground text-sm w-48">{label}</td>
        <td className={`py-1 text-sm text-right ${bold ? 'text-foreground' : ''}`}>{value}</td>
      </tr>
    </>
  )
}

export function PayslipDetailDialog({ record, onOpenChange }: Props) {
  if (!record) return null

  const emp = record.employee

  return (
    <Dialog open={!!record} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Payslip — {record.period_label}</DialogTitle>
          {emp && (
            <div className="text-sm text-muted-foreground">
              <p className="font-medium text-foreground">{emp.user.name}</p>
              <p>{emp.position}{emp.department ? ` · ${emp.department.name}` : ''}</p>
              <p className="font-mono text-xs">{emp.employee_number}</p>
            </div>
          )}
        </DialogHeader>

        <div className="flex justify-end">
          <Button variant="outline" size="sm" onClick={() => printPayslip(record)}>
            <Printer className="w-4 h-4 mr-2" />
            Print / PDF
          </Button>
        </div>

        <ScrollArea className="max-h-[65vh]">
          <div className="pr-2">
            {/* Attendance Summary */}
            <h4 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-2">Attendance</h4>
            <div className="grid grid-cols-4 gap-2 mb-4">
              {[
                { label: 'Working', value: record.working_days },
                { label: 'Present', value: record.present_days },
                { label: 'Leave',   value: record.leave_days },
                { label: 'Absent',  value: record.absent_days },
              ].map((item) => (
                <div key={item.label} className="text-center bg-muted/50 rounded-lg py-2">
                  <p className="text-lg font-bold">{item.value}</p>
                  <p className="text-xs text-muted-foreground">{item.label}</p>
                </div>
              ))}
            </div>

            {/* Salary Breakdown */}
            <h4 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground mb-2">Salary Breakdown</h4>
            <table className="w-full">
              <tbody>
                <Row label="Basic Salary"     value={IDR(record.basic_salary)} />
                <Row label="Allowances"       value={IDR(record.allowances)} />
                <Row label="Overtime"         value={IDR(record.overtime_pay)} />
                <Row label="Gross Salary"     value={IDR(record.gross_salary)} bold separator />
                <Row label="Absent Deduction" value={`– ${IDR(record.absent_deduction)}`} />
                <Row label="Other Deductions" value={`– ${IDR(record.other_deductions)}`} />
                <Row label="PPh21 (Tax 5%)"   value={`– ${IDR(record.tax_deduction)}`} />
                <Row label="BPJS (3%)"        value={`– ${IDR(record.bpjs_deduction)}`} />
                <Row label="Total Deductions" value={`– ${IDR(record.total_deductions)}`} bold separator />
              </tbody>
            </table>

            {/* Net Salary */}
            <div className="mt-3 rounded-lg bg-primary/5 border border-primary/20 p-4 flex justify-between items-center">
              <span className="text-sm font-semibold">Net Salary</span>
              <span className="text-xl font-bold text-primary">{IDR(record.net_salary)}</span>
            </div>

            {/* Status & Notes */}
            <div className="mt-3 space-y-1 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Status</span>
                <span className="capitalize font-medium">{record.status}</span>
              </div>
              {record.paid_at && (
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Paid At</span>
                  <span>{new Date(record.paid_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}</span>
                </div>
              )}
              {record.notes && (
                <div className="pt-1">
                  <span className="text-muted-foreground">Notes: </span>
                  <span>{record.notes}</span>
                </div>
              )}
            </div>
          </div>
        </ScrollArea>
      </DialogContent>
    </Dialog>
  )
}
