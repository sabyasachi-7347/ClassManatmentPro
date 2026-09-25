import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Empty, Spinner, useToast } from '../components/ui';
import { api } from '../lib/api';
import { useLoad } from '../lib/hooks';
import { AttendanceSession, AttendanceStatus, Batch, initials, Student, today } from '../lib/types';

const NEXT: Record<AttendanceStatus, AttendanceStatus> = {
  present: 'absent',
  absent: 'late',
  late: 'excused',
  excused: 'present',
};
const MARK: Record<AttendanceStatus, string> = { present: '✓', absent: '✕', late: 'L', excused: 'E' };

/** Everyone starts "present" — tap a student to cycle absent → late → excused. */
export function Attendance() {
  const toast = useToast();
  const [params, setParams] = useSearchParams();
  const batches = useLoad(() => api.get<Batch[]>('/batches'));
  const batchId = params.get('batch') ?? batches.data?.[0]?.id ?? '';
  const [date, setDate] = useState(today());
  const [marks, setMarks] = useState<Record<string, AttendanceStatus>>({});
  const [saving, setSaving] = useState(false);

  const roster = useLoad(
    async () => {
      if (!batchId) return { students: [] as Student[], existing: undefined };
      const [students, sessions] = await Promise.all([
        api.get<Student[]>(`/students?batchId=${batchId}`),
        api.get<AttendanceSession[]>(`/attendance/batches/${batchId}?from=${date}&to=${date}`),
      ]);
      return { students, existing: sessions[0] };
    },
    [batchId, date],
  );

  useEffect(() => {
    if (!roster.data) return;
    const init: Record<string, AttendanceStatus> = {};
    roster.data.students.forEach((s) => (init[s.id] = roster.data!.existing?.records[s.id] ?? 'present'));
    setMarks(init);
  }, [roster.data]);

  const count = (s: AttendanceStatus) => Object.values(marks).filter((m) => m === s).length;

  async function save() {
    setSaving(true);
    try {
      await api.put(`/attendance/batches/${batchId}/${date}`, {
        records: Object.entries(marks).map(([studentId, status]) => ({ studentId, status })),
      });
      toast('Attendance saved');
      roster.reload();
    } catch (e) {
      toast((e as Error).message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <>
      <div className="page-head an">
        <div>
          <h1 className="h1">Attendance</h1>
          <p className="sub">
            {roster.data?.existing ? 'Already marked — edits will overwrite.' : 'Tap a student to change their status.'}
          </p>
        </div>
        <div className="spacer" />
        <select className="ip" style={{ width: 220 }} value={batchId} onChange={(e) => setParams({ batch: e.target.value })}>
          {batches.data?.map((b) => <option key={b.id} value={b.id}>{b.name}</option>)}
        </select>
        <input className="ip" style={{ width: 160 }} type="date" value={date} max={today()} onChange={(e) => setDate(e.target.value)} />
      </div>
      {(batches.loading || roster.loading) && <Spinner />}
      {batches.data && !batches.data.length && <Empty title="No batches assigned to you" />}
      {roster.data && !!batchId && (
        <div className="an2" style={{ maxWidth: 640 }}>
          <div className="cnt">
            <div><b style={{ color: 'var(--lime)' }}>{count('present')}</b><small>Present</small></div>
            <div><b style={{ color: 'var(--hot)' }}>{count('absent')}</b><small>Absent</small></div>
            <div><b style={{ color: 'var(--amb)' }}>{count('late')}</b><small>Late</small></div>
            <div><b>{count('excused')}</b><small>Excused</small></div>
          </div>
          {!roster.data.students.length && <Empty title="No students in this batch" />}
          {roster.data.students.map((s) => {
            const m = marks[s.id] ?? 'present';
            return (
              <div key={s.id} className={`prs ${m === 'absent' ? 'ab' : ''}`} role="button" tabIndex={0}
                onClick={() => setMarks((p) => ({ ...p, [s.id]: NEXT[m] }))}
                onKeyDown={(e) => e.key === 'Enter' && setMarks((p) => ({ ...p, [s.id]: NEXT[m] }))}>
                <span className="av">{initials(s.name)}</span>
                <span style={{ flex: 1, fontWeight: 500 }}>{s.name}</span>
                <span className={`pl ${m === 'present' ? 'l' : m === 'absent' ? 'h' : m === 'late' ? 'm' : 'x'}`}>{m}</span>
                <span className="tk">{MARK[m]}</span>
              </div>
            );
          })}
          {!!roster.data.students.length && (
            <button className="b p lg blk" style={{ marginTop: 10 }} disabled={saving} onClick={save}>
              {saving ? 'Saving…' : `Save attendance · ${date}`}
            </button>
          )}
        </div>
      )}
    </>
  );
}
