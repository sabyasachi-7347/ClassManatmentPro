import { useEffect, useMemo, useState } from 'react';
import { Empty, Spinner, useToast } from '../components/ui';
import { api } from '../lib/api';
import { useLoad } from '../lib/hooks';
import { Batch, Student } from '../lib/types';

const key = (s: string, b: string) => `${s}|${b}`;

/** Students × batches matrix. Click-drag to "paint" enrollments, then save in one request. */
export function Enrollment() {
  const toast = useToast();
  const students = useLoad(() => api.get<Student[]>('/students'));
  const batches = useLoad(() => api.get<Batch[]>('/batches'));
  const [pending, setPending] = useState<Map<string, boolean>>(new Map());
  const [paint, setPaint] = useState<boolean | null>(null);
  const [saving, setSaving] = useState(false);

  const base = useMemo(() => {
    const set = new Set<string>();
    students.data?.forEach((s) => s.batchIds.forEach((b) => set.add(key(s.id, b))));
    return set;
  }, [students.data]);

  const isOn = (s: string, b: string) => pending.get(key(s, b)) ?? base.has(key(s, b));

  const apply = (s: string, b: string, value: boolean) =>
    setPending((prev) => {
      const next = new Map(prev);
      if (base.has(key(s, b)) === value) next.delete(key(s, b));
      else next.set(key(s, b), value);
      return next;
    });

  useEffect(() => {
    const stop = () => setPaint(null);
    window.addEventListener('pointerup', stop);
    return () => window.removeEventListener('pointerup', stop);
  }, []);

  async function save() {
    setSaving(true);
    try {
      const changes = [...pending].map(([k, enrolled]) => {
        const [studentId, batchId] = k.split('|');
        return { studentId, batchId, enrolled };
      });
      await api.put('/enrollments', { changes });
      toast(`Saved ${changes.length} change${changes.length === 1 ? '' : 's'}`);
      setPending(new Map());
      await students.reload();
    } catch (e) {
      toast((e as Error).message);
    } finally {
      setSaving(false);
    }
  }

  if (students.loading || batches.loading) return <Spinner />;
  const bs = batches.data ?? [];
  const ss = students.data ?? [];

  return (
    <>
      <div className="page-head an">
        <div>
          <h1 className="h1">Enrollment</h1>
          <p className="sub">Click and drag across cells to enroll or remove students in bulk.</p>
        </div>
        <div className="spacer" />
        {pending.size > 0 && <span className="pl m">{pending.size} unsaved</span>}
        <button className="b" disabled={!pending.size} onClick={() => setPending(new Map())}>Reset</button>
        <button className="b p" disabled={!pending.size || saving} onClick={save}>{saving ? 'Saving…' : 'Save'}</button>
      </div>
      {!bs.length || !ss.length ? (
        <Empty title="Nothing to show">Add batches and students first.</Empty>
      ) : (
        <div className="k pad0 an2">
          <div className="mx paint">
            <table>
              <thead>
                <tr>
                  <th className="cn">Student</th>
                  {bs.map((b) => <th className="bt" key={b.id}><div>{b.name}</div></th>)}
                </tr>
              </thead>
              <tbody>
                {ss.map((s) => (
                  <tr key={s.id}>
                    <td className="rh">{s.name}</td>
                    {bs.map((b) => {
                      const on = isOn(s.id, b.id);
                      return (
                        <td className="cl" key={b.id}>
                          <button
                            className={`cb ${on ? 'on' : ''}`}
                            aria-pressed={on}
                            aria-label={`${s.name} in ${b.name}`}
                            onPointerDown={(e) => {
                              e.preventDefault();
                              setPaint(!on);
                              apply(s.id, b.id, !on);
                            }}
                            onPointerEnter={() => paint !== null && apply(s.id, b.id, paint)}
                            onKeyDown={(e) => {
                              if (e.key === ' ' || e.key === 'Enter') {
                                e.preventDefault();
                                apply(s.id, b.id, !on);
                              }
                            }}
                          >
                            <i />
                          </button>
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </>
  );
}
