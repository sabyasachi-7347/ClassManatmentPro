import { FormEvent, useMemo, useState } from 'react';
import { Empty, Field, Modal, Spinner, useToast } from '../components/ui';
import { api } from '../lib/api';
import { useAuth } from '../lib/auth';
import { useLoad } from '../lib/hooks';
import { Batch, initials, isStaff, Student } from '../lib/types';

export function Students() {
  const { me } = useAuth();
  const staff = isStaff(me?.role);
  const { data, loading, error, reload } = useLoad(() => api.get<Student[]>('/students'));
  const batches = useLoad(() => api.get<Batch[]>('/batches'));
  const [q, setQ] = useState('');
  const [editing, setEditing] = useState<Partial<Student> | null>(null);
  const batchName = (id: string) => batches.data?.find((b) => b.id === id)?.name;

  const list = useMemo(
    () => (data ?? []).filter((s) => `${s.name} ${s.phone ?? ''} ${s.email ?? ''}`.toLowerCase().includes(q.toLowerCase())),
    [data, q],
  );

  return (
    <>
      <div className="page-head an">
        <div>
          <h1 className="h1">Students</h1>
          <p className="sub">{data?.length ?? 0} students</p>
        </div>
        <div className="spacer" />
        <input className="ip" style={{ width: 240 }} placeholder="Search…" value={q} onChange={(e) => setQ(e.target.value)} />
        {staff && <button className="b p" onClick={() => setEditing({})}>+ Add student</button>}
      </div>
      {loading && <Spinner />}
      {error && <div className="err">{error}</div>}
      {data && !list.length && <Empty title="No students found" />}
      {!!list.length && (
        <div className="k pad0 an2" style={{ overflowX: 'auto' }}>
          <table className="tb">
            <thead><tr><th>Student</th><th>Contact</th><th>Guardian</th><th>Batches</th><th>Status</th>{staff && <th />}</tr></thead>
            <tbody>
              {list.map((s) => (
                <tr key={s.id}>
                  <td>
                    <div className="rw">
                      <span className="av a">{initials(s.name)}</span>
                      <div><div className="nm">{s.name}</div><div className="sm">{s.grade}</div></div>
                    </div>
                  </td>
                  <td className="sm">{s.phone}<br />{s.email}</td>
                  <td className="sm">{s.guardianName}<br />{s.guardianPhone}</td>
                  <td className="sm">{s.batchIds.map(batchName).filter(Boolean).join(', ') || '—'}</td>
                  <td><span className={`pl ${s.status === 'active' ? 'l' : 'x'}`}>{s.status}</span></td>
                  {staff && <td><button className="b s" onClick={() => setEditing(s)}>Edit</button></td>}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {editing && (
        <StudentForm student={editing} batches={batches.data ?? []} onClose={() => setEditing(null)}
          onSaved={() => { setEditing(null); reload(); }} />
      )}
    </>
  );
}

function StudentForm({ student, batches, onClose, onSaved }: {
  student: Partial<Student>; batches: Batch[]; onClose: () => void; onSaved: () => void;
}) {
  const toast = useToast();
  const [f, setF] = useState<Partial<Student>>({ batchIds: [], ...student });
  const [err, setErr] = useState('');
  const set = (k: keyof Student, v: unknown) => setF((p) => ({ ...p, [k]: v }));
  const text = (k: keyof Student, label: string, type = 'text') => (
    <Field label={label}>
      <input className="ip" type={type} value={(f[k] as string) ?? ''} onChange={(e) => set(k, e.target.value || undefined)} />
    </Field>
  );

  async function submit(e: FormEvent) {
    e.preventDefault();
    const { id, ...rest } = f;
    const body = { name: rest.name, phone: rest.phone, email: rest.email, guardianName: rest.guardianName,
      guardianPhone: rest.guardianPhone, grade: rest.grade, batchIds: rest.batchIds, ...(id && { status: rest.status }) };
    try {
      if (id) await api.patch(`/students/${id}`, body);
      else await api.post('/students', body);
      toast(id ? 'Student updated' : 'Student added');
      onSaved();
    } catch (e) {
      setErr((e as Error).message);
    }
  }

  return (
    <Modal title={f.id ? 'Edit student' : 'Add student'} onClose={onClose}>
      <form onSubmit={submit}>
        <Field label="Full name">
          <input className="ip" required value={f.name ?? ''} onChange={(e) => set('name', e.target.value)} />
        </Field>
        <div className="grid2">
          {text('phone', 'Phone', 'tel')}
          {text('email', 'Email', 'email')}
          {text('guardianName', 'Guardian name')}
          {text('guardianPhone', 'Guardian phone', 'tel')}
          {text('grade', 'Grade / class')}
          {f.id && (
            <Field label="Status">
              <select className="ip" value={f.status} onChange={(e) => set('status', e.target.value)}>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </Field>
          )}
        </div>
        <span className="lbl">Batches</span>
        <div className="row">
          {batches.map((b) => {
            const on = f.batchIds?.includes(b.id);
            return (
              <button type="button" key={b.id} className={`chp ${on ? 'on' : ''}`}
                onClick={() => set('batchIds', on ? f.batchIds!.filter((x) => x !== b.id) : [...(f.batchIds ?? []), b.id])}>
                {b.name}
              </button>
            );
          })}
        </div>
        <div className="row" style={{ marginTop: 18 }}>
          <div className="spacer" />
          <button type="button" className="b" onClick={onClose}>Cancel</button>
          <button className="b p">Save</button>
        </div>
        {err && <div className="err">{err}</div>}
      </form>
    </Modal>
  );
}
