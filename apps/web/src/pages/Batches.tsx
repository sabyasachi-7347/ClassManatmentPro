import { FormEvent, useState } from 'react';
import { Empty, Field, Modal, Spinner, useToast } from '../components/ui';
import { api } from '../lib/api';
import { useAuth } from '../lib/auth';
import { useLoad } from '../lib/hooks';
import { Batch, DAYS, isStaff, Member, money, Slot } from '../lib/types';

export function Batches() {
  const { me } = useAuth();
  const staff = isStaff(me?.role);
  const { data, loading, error, reload } = useLoad(() => api.get<Batch[]>('/batches'));
  const teachers = useLoad(
    () => (staff ? api.get<Member[]>('/members?role=teacher') : Promise.resolve([])),
    [staff],
  );
  const [editing, setEditing] = useState<Partial<Batch> | null>(null);
  const teacherName = (id: string) => teachers.data?.find((t) => t.id === id)?.name ?? '—';

  return (
    <>
      <div className="page-head an">
        <div>
          <h1 className="h1">Batches</h1>
          <p className="sub">Classes, schedules and who teaches them.</p>
        </div>
        <div className="spacer" />
        {staff && <button className="b p" onClick={() => setEditing({ schedule: [], teacherIds: [] })}>+ New batch</button>}
      </div>
      {loading && <Spinner />}
      {error && <div className="err">{error}</div>}
      {data && !data.length && <Empty title="No batches yet">Create your first batch to get started.</Empty>}
      {!!data?.length && (
        <div className="k pad0 an2" style={{ overflowX: 'auto' }}>
          <table className="tb">
            <thead>
              <tr><th>Batch</th><th>Schedule</th><th>Teachers</th><th>Room</th><th>Fee / mo</th>{staff && <th />}</tr>
            </thead>
            <tbody>
              {data.map((b) => (
                <tr key={b.id}>
                  <td><div className="nm">{b.name}</div><div className="sm">{b.subject}</div></td>
                  <td className="sm">
                    {b.schedule.map((s) => `${DAYS[s.day]} ${s.start}–${s.end}`).join(', ') || '—'}
                  </td>
                  <td className="sm">{b.teacherIds.map(teacherName).join(', ') || '—'}</td>
                  <td className="sm">{b.room || '—'}</td>
                  <td className="mono">{b.monthlyFee != null ? money(b.monthlyFee) : '—'}</td>
                  {staff && <td><button className="b s" onClick={() => setEditing(b)}>Edit</button></td>}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {editing && (
        <BatchForm
          batch={editing}
          teachers={teachers.data ?? []}
          onClose={() => setEditing(null)}
          onSaved={() => {
            setEditing(null);
            reload();
          }}
        />
      )}
    </>
  );
}

function BatchForm({
  batch,
  teachers,
  onClose,
  onSaved,
}: {
  batch: Partial<Batch>;
  teachers: Member[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const toast = useToast();
  const [f, setF] = useState<Partial<Batch>>(batch);
  const [err, setErr] = useState('');
  const set = <K extends keyof Batch>(k: K, v: Batch[K]) => setF((p) => ({ ...p, [k]: v }));
  const schedule = f.schedule ?? [];
  const setSlot = (i: number, patch: Partial<Slot>) =>
    set('schedule', schedule.map((s, j) => (j === i ? { ...s, ...patch } : s)));

  async function submit(e: FormEvent) {
    e.preventDefault();
    const body = {
      name: f.name,
      subject: f.subject,
      room: f.room || undefined,
      monthlyFee: f.monthlyFee ?? undefined,
      teacherIds: f.teacherIds ?? [],
      schedule,
    };
    try {
      if (f.id) await api.patch(`/batches/${f.id}`, body);
      else await api.post('/batches', body);
      toast(f.id ? 'Batch updated' : 'Batch created');
      onSaved();
    } catch (e) {
      setErr((e as Error).message);
    }
  }

  return (
    <Modal title={f.id ? 'Edit batch' : 'New batch'} onClose={onClose}>
      <form onSubmit={submit}>
        <div className="grid2">
          <Field label="Name"><input className="ip" required value={f.name ?? ''} onChange={(e) => set('name', e.target.value)} /></Field>
          <Field label="Subject"><input className="ip" required value={f.subject ?? ''} onChange={(e) => set('subject', e.target.value)} /></Field>
          <Field label="Room"><input className="ip" value={f.room ?? ''} onChange={(e) => set('room', e.target.value)} /></Field>
          <Field label="Monthly fee">
            <input className="ip" type="number" min={0} value={f.monthlyFee ?? ''}
              onChange={(e) => set('monthlyFee', e.target.value === '' ? undefined : Number(e.target.value))} />
          </Field>
        </div>
        <span className="lbl">Teachers</span>
        <div className="row" style={{ marginBottom: 14 }}>
          {teachers.map((t) => {
            const on = f.teacherIds?.includes(t.id);
            return (
              <button type="button" key={t.id} className={`chp ${on ? 'on' : ''}`}
                onClick={() => set('teacherIds', on ? f.teacherIds!.filter((x) => x !== t.id) : [...(f.teacherIds ?? []), t.id])}>
                {t.name}
              </button>
            );
          })}
          {!teachers.length && <span className="muted">Invite teachers under “Team & access”.</span>}
        </div>
        <span className="lbl">Schedule</span>
        {schedule.map((s, i) => (
          <div className="row" key={i} style={{ marginBottom: 8 }}>
            <select className="ip" style={{ width: 90 }} value={s.day} onChange={(e) => setSlot(i, { day: Number(e.target.value) })}>
              {DAYS.map((d, n) => <option key={d} value={n}>{d}</option>)}
            </select>
            <input className="ip" style={{ width: 110 }} type="time" value={s.start} onChange={(e) => setSlot(i, { start: e.target.value })} />
            <input className="ip" style={{ width: 110 }} type="time" value={s.end} onChange={(e) => setSlot(i, { end: e.target.value })} />
            <button type="button" className="b s gh" onClick={() => set('schedule', schedule.filter((_, j) => j !== i))}>Remove</button>
          </div>
        ))}
        <button type="button" className="b s" onClick={() => set('schedule', [...schedule, { day: 1, start: '17:00', end: '18:00' }])}>
          + Add slot
        </button>
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
