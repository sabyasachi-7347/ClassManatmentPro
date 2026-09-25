import { FormEvent, useState } from 'react';
import { Empty, Field, Modal, Spinner, useToast } from '../components/ui';
import { api, qs } from '../lib/api';
import { useAuth } from '../lib/auth';
import { useLoad } from '../lib/hooks';
import { Fee, isStaff, money, Student, today } from '../lib/types';

const FILTERS = [
  { v: 'due', l: 'Due' },
  { v: 'paid', l: 'Paid' },
  { v: '', l: 'All' },
];

export function Fees() {
  const { me } = useAuth();
  const staff = isStaff(me?.role);
  const toast = useToast();
  const [status, setStatus] = useState('due');
  const { data, loading, error, reload } = useLoad(() => api.get<Fee[]>(`/fees${qs({ status })}`), [status]);
  const [paying, setPaying] = useState<Fee | null>(null);
  const [gen, setGen] = useState(false);
  const [create, setCreate] = useState(false);
  const total = (data ?? []).reduce((s, f) => s + f.amount, 0);
  const overdue = (data ?? []).filter((f) => f.overdue);

  return (
    <>
      <div className="page-head an">
        <div>
          <h1 className="h1">Fees</h1>
          <p className="sub">{data?.length ?? 0} invoices · {money(total)} total</p>
        </div>
        <div className="spacer" />
        <div className="sg" style={{ width: 240 }}>
          {FILTERS.map((f) => (
            <button key={f.l} className={status === f.v ? 'on' : ''} onClick={() => setStatus(f.v)}>{f.l}</button>
          ))}
        </div>
        {staff && <button className="b" onClick={() => setCreate(true)}>+ Invoice</button>}
        {staff && <button className="b p" onClick={() => setGen(true)}>Generate monthly</button>}
      </div>
      {status === 'due' && overdue.length > 0 && (
        <div className="bnr">
          <div className="t"><i />{overdue.length} overdue invoice{overdue.length > 1 ? 's' : ''}</div>
          <p>{money(overdue.reduce((s, f) => s + f.amount, 0))} is past its due date.</p>
        </div>
      )}
      {loading && <Spinner />}
      {error && <div className="err">{error}</div>}
      {data && !data.length && <Empty title="All clear">No invoices in this view.</Empty>}
      {!!data?.length && (
        <div className="k pad0 an2" style={{ overflowX: 'auto' }}>
          <table className="tb">
            <thead><tr><th>Student</th><th>Period</th><th>Due</th><th>Amount</th><th>Status</th>{staff && <th />}</tr></thead>
            <tbody>
              {data.map((f) => (
                <tr key={f.id}>
                  <td className="nm">{f.studentName}</td>
                  <td className="sm">{f.period ?? '—'}</td>
                  <td className="sm mono">{f.dueDate}</td>
                  <td className="mono">{money(f.amount)}</td>
                  <td>
                    {f.status === 'paid' ? <span className="pl l">Paid · {f.payment?.method}</span>
                      : f.status === 'waived' ? <span className="pl x">Waived</span>
                      : f.overdue ? <span className="pl h">Overdue</span> : <span className="pl m">Due</span>}
                  </td>
                  {staff && (
                    <td>{f.status === 'due' && <button className="b s p" onClick={() => setPaying(f)}>Record payment</button>}</td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {paying && (
        <PayForm fee={paying} onClose={() => setPaying(null)} onSaved={() => { setPaying(null); toast('Payment recorded'); reload(); }} />
      )}
      {gen && (
        <GenerateForm onClose={() => setGen(false)}
          onSaved={(r) => { setGen(false); toast(`Created ${r.created}, skipped ${r.skipped}`); reload(); }} />
      )}
      {create && (
        <CreateForm onClose={() => setCreate(false)} onSaved={() => { setCreate(false); toast('Invoice created'); reload(); }} />
      )}
    </>
  );
}

function PayForm({ fee, onClose, onSaved }: { fee: Fee; onClose: () => void; onSaved: () => void }) {
  const [method, setMethod] = useState('upi');
  const [reference, setReference] = useState('');
  const [paidOn, setPaidOn] = useState(today());
  const [err, setErr] = useState('');
  async function submit(e: FormEvent) {
    e.preventDefault();
    try {
      await api.post(`/fees/${fee.id}/pay`, { method, reference: reference || undefined, paidOn });
      onSaved();
    } catch (e) { setErr((e as Error).message); }
  }
  return (
    <Modal title={`Record payment · ${money(fee.amount)}`} onClose={onClose}>
      <form onSubmit={submit}>
        <p className="muted" style={{ marginBottom: 14 }}>{fee.studentName} · {fee.period ?? fee.dueDate}</p>
        <span className="lbl">Method</span>
        <div className="row" style={{ marginBottom: 14 }}>
          {['upi', 'cash', 'card', 'bank', 'other'].map((m) => (
            <button type="button" key={m} className={`chp ${method === m ? 'on' : ''}`} onClick={() => setMethod(m)}>{m.toUpperCase()}</button>
          ))}
        </div>
        <div className="grid2">
          <Field label="Reference"><input className="ip" value={reference} onChange={(e) => setReference(e.target.value)} /></Field>
          <Field label="Paid on"><input className="ip" type="date" value={paidOn} onChange={(e) => setPaidOn(e.target.value)} /></Field>
        </div>
        <button className="b p lg blk">Confirm</button>
        {err && <div className="err">{err}</div>}
      </form>
    </Modal>
  );
}

function GenerateForm({ onClose, onSaved }: { onClose: () => void; onSaved: (r: { created: number; skipped: number }) => void }) {
  const now = new Date();
  const [period, setPeriod] = useState(now.toLocaleDateString('en-CA').slice(0, 7));
  const [dueDate, setDueDate] = useState(`${period}-05`);
  const [err, setErr] = useState('');
  async function submit(e: FormEvent) {
    e.preventDefault();
    try { onSaved(await api.post('/fees/generate', { period, dueDate })); }
    catch (e) { setErr((e as Error).message); }
  }
  return (
    <Modal title="Generate monthly invoices" onClose={onClose}>
      <form onSubmit={submit}>
        <p className="muted" style={{ marginBottom: 14 }}>
          Creates one invoice per active student, summing the monthly fee of each batch they’re in.
          Students who already have an invoice for the month are skipped.
        </p>
        <div className="grid2">
          <Field label="Month"><input className="ip" type="month" required value={period} onChange={(e) => setPeriod(e.target.value)} /></Field>
          <Field label="Due date"><input className="ip" type="date" required value={dueDate} onChange={(e) => setDueDate(e.target.value)} /></Field>
        </div>
        <button className="b p lg blk">Generate</button>
        {err && <div className="err">{err}</div>}
      </form>
    </Modal>
  );
}

function CreateForm({ onClose, onSaved }: { onClose: () => void; onSaved: () => void }) {
  const students = useLoad(() => api.get<Student[]>('/students'));
  const [studentId, setStudentId] = useState('');
  const [amount, setAmount] = useState('');
  const [dueDate, setDueDate] = useState(today());
  const [note, setNote] = useState('');
  const [err, setErr] = useState('');
  async function submit(e: FormEvent) {
    e.preventDefault();
    try {
      await api.post('/fees', { studentId, amount: Number(amount), dueDate, note: note || undefined });
      onSaved();
    } catch (e) { setErr((e as Error).message); }
  }
  return (
    <Modal title="New invoice" onClose={onClose}>
      <form onSubmit={submit}>
        <Field label="Student">
          <select className="ip" required value={studentId} onChange={(e) => setStudentId(e.target.value)}>
            <option value="">Select…</option>
            {students.data?.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
          </select>
        </Field>
        <div className="grid2">
          <Field label="Amount"><input className="ip" type="number" min={1} required value={amount} onChange={(e) => setAmount(e.target.value)} /></Field>
          <Field label="Due date"><input className="ip" type="date" required value={dueDate} onChange={(e) => setDueDate(e.target.value)} /></Field>
        </div>
        <Field label="Note"><input className="ip" value={note} onChange={(e) => setNote(e.target.value)} /></Field>
        <button className="b p lg blk">Create</button>
        {err && <div className="err">{err}</div>}
      </form>
    </Modal>
  );
}
