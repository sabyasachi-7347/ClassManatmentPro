import { FormEvent, useState } from 'react';
import { Empty, Field, Modal, Spinner, useToast } from '../components/ui';
import { api } from '../lib/api';
import { useLoad } from '../lib/hooks';
import { initials, Member, Role, Student } from '../lib/types';

const ROLES: Role[] = ['admin', 'teacher', 'student', 'parent'];

export function Members() {
  const toast = useToast();
  const { data, loading, reload } = useLoad(() => api.get<Member[]>('/members'));
  const [inviting, setInviting] = useState(false);
  const [link, setLink] = useState<string | null>(null);

  async function remove(m: Member) {
    if (!confirm(`Remove ${m.name}'s access?`)) return;
    try { await api.del(`/members/${m.id}`); toast('Access removed'); reload(); }
    catch (e) { toast((e as Error).message); }
  }

  return (
    <>
      <div className="page-head an">
        <div>
          <h1 className="h1">Team & access</h1>
          <p className="sub">Admins, teachers, and student/parent logins.</p>
        </div>
        <div className="spacer" />
        <button className="b p" onClick={() => setInviting(true)}>+ Invite</button>
      </div>
      {loading && <Spinner />}
      {data && !data.length && <Empty title="No members yet" />}
      {!!data?.length && (
        <div className="k pad0 an2" style={{ overflowX: 'auto' }}>
          <table className="tb">
            <thead><tr><th>Name</th><th>Email</th><th>Role</th><th /></tr></thead>
            <tbody>
              {data.map((m) => (
                <tr key={m.id}>
                  <td><div className="rw"><span className="av">{initials(m.name)}</span><span className="nm">{m.name}</span></div></td>
                  <td className="sm">{m.email}</td>
                  <td><span className={`pl ${m.role === 'owner' ? 'a' : 'x'}`}>{m.role}</span></td>
                  <td>{m.role !== 'owner' && <button className="b s gh" onClick={() => remove(m)}>Remove</button>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {inviting && (
        <InviteForm onClose={() => setInviting(false)}
          onSaved={(l) => { setInviting(false); setLink(l); reload(); }} />
      )}
      {link && (
        <Modal title="Invite created" onClose={() => setLink(null)}>
          <p className="muted" style={{ marginBottom: 12 }}>
            Share this link so they can set a password (it’s also valid for “Forgot password” later).
          </p>
          <textarea className="ip mono" rows={4} readOnly value={link} onFocus={(e) => e.target.select()} />
          <button className="b p blk" style={{ marginTop: 12 }}
            onClick={() => navigator.clipboard.writeText(link).then(() => toast('Link copied'))}>Copy link</button>
        </Modal>
      )}
    </>
  );
}

function InviteForm({ onClose, onSaved }: { onClose: () => void; onSaved: (link: string) => void }) {
  const students = useLoad(() => api.get<Student[]>('/students'));
  const [f, setF] = useState({ name: '', email: '', phone: '', role: 'teacher' as Role, studentIds: [] as string[] });
  const [err, setErr] = useState('');
  const needsStudents = f.role === 'student' || f.role === 'parent';

  async function submit(e: FormEvent) {
    e.preventDefault();
    try {
      const res = await api.post<{ setPasswordLink: string }>('/members', {
        name: f.name, email: f.email, phone: f.phone || undefined, role: f.role,
        studentIds: needsStudents ? f.studentIds : undefined,
      });
      onSaved(res.setPasswordLink);
    } catch (e) { setErr((e as Error).message); }
  }

  return (
    <Modal title="Invite member" onClose={onClose}>
      <form onSubmit={submit}>
        <div className="sg" style={{ marginBottom: 14 }}>
          {ROLES.map((r) => (
            <button type="button" key={r} className={f.role === r ? 'on' : ''} onClick={() => setF({ ...f, role: r })}>{r}</button>
          ))}
        </div>
        <div className="grid2">
          <Field label="Name"><input className="ip" required value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} /></Field>
          <Field label="Email"><input className="ip" type="email" required value={f.email} onChange={(e) => setF({ ...f, email: e.target.value })} /></Field>
        </div>
        <Field label="Phone"><input className="ip" type="tel" value={f.phone} onChange={(e) => setF({ ...f, phone: e.target.value })} /></Field>
        {needsStudents && (
          <Field label={f.role === 'parent' ? 'Children' : 'Linked student record'}>
            <select className="ip" multiple={f.role === 'parent'} required
              value={f.role === 'parent' ? f.studentIds : f.studentIds[0] ?? ''}
              onChange={(e) => setF({ ...f, studentIds: [...e.target.selectedOptions].map((o) => o.value).filter(Boolean) })}>
              {f.role === 'student' && <option value="">Select…</option>}
              {students.data?.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
            </select>
          </Field>
        )}
        <button className="b p lg blk">Send invite</button>
        {err && <div className="err">{err}</div>}
      </form>
    </Modal>
  );
}
