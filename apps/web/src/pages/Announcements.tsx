import { FormEvent, useState } from 'react';
import { Empty, Field, Spinner, useToast } from '../components/ui';
import { api } from '../lib/api';
import { useAuth } from '../lib/auth';
import { useLoad } from '../lib/hooks';
import { Announcement, Batch } from '../lib/types';

export function Announcements() {
  const { me } = useAuth();
  const toast = useToast();
  const canPost = me?.role === 'owner' || me?.role === 'admin' || me?.role === 'teacher';
  const { data, loading, reload } = useLoad(() => api.get<Announcement[]>('/announcements'));
  const batches = useLoad(() => api.get<Batch[]>('/batches'));
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [batchIds, setBatchIds] = useState<string[]>([]);
  const batchName = (id: string) => batches.data?.find((b) => b.id === id)?.name ?? id;

  async function post(e: FormEvent) {
    e.preventDefault();
    try {
      await api.post('/announcements', { title, body, batchIds });
      setTitle(''); setBody(''); setBatchIds([]);
      toast('Announcement posted');
      reload();
    } catch (e) { toast((e as Error).message); }
  }

  return (
    <>
      <div className="an">
        <h1 className="h1">Announcements</h1>
        <p className="sub">Notices for the whole institute or specific batches.</p>
      </div>
      <div className="bn an2">
        {canPost && (
          <form className="k w2" onSubmit={post} style={{ alignSelf: 'start' }}>
            <div className="kh"><h3>New announcement</h3></div>
            <Field label="Title"><input className="ip" required value={title} onChange={(e) => setTitle(e.target.value)} /></Field>
            <Field label="Message"><textarea className="ip" required rows={4} value={body} onChange={(e) => setBody(e.target.value)} /></Field>
            <span className="lbl">Audience {batchIds.length ? '' : '· everyone'}</span>
            <div className="row" style={{ marginBottom: 14 }}>
              {batches.data?.map((b) => {
                const on = batchIds.includes(b.id);
                return (
                  <button type="button" key={b.id} className={`chp ${on ? 'on' : ''}`}
                    onClick={() => setBatchIds(on ? batchIds.filter((x) => x !== b.id) : [...batchIds, b.id])}>{b.name}</button>
                );
              })}
            </div>
            <button className="b p blk">Post</button>
          </form>
        )}
        <div className={`k ${canPost ? 'w2' : 'w4'}`}>
          <div className="kh"><h3>Recent</h3></div>
          {loading && <Spinner />}
          {data && !data.length && <Empty title="No announcements yet" />}
          {data?.map((a) => (
            <div key={a.id} className="lb" style={{ alignItems: 'flex-start', flexDirection: 'column', gap: 6 }}>
              <div className="row" style={{ width: '100%' }}>
                <b style={{ fontSize: 14 }}>{a.title}</b>
                <div className="spacer" />
                <span className="muted">{a.createdAt ? new Date(a.createdAt).toLocaleDateString() : ''}</span>
              </div>
              <div style={{ fontSize: 13, whiteSpace: 'pre-wrap' }}>{a.body}</div>
              <div className="row">
                {a.batchIds.length ? a.batchIds.map((b) => <span className="pl a" key={b}>{batchName(b)}</span>)
                  : <span className="pl x">Everyone</span>}
                {a.authorName && <span className="muted">by {a.authorName}</span>}
              </div>
            </div>
          ))}
        </div>
      </div>
    </>
  );
}
