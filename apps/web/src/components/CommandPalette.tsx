import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { NavItem } from './nav';

/** ⌘K / Ctrl+K palette for jumping between modules. */
export function CommandPalette({ items, open, onClose }: { items: NavItem[]; open: boolean; onClose: () => void }) {
  const [q, setQ] = useState('');
  const [sel, setSel] = useState(0);
  const nav = useNavigate();
  const list = useMemo(
    () => items.filter((i) => i.label.toLowerCase().includes(q.toLowerCase())),
    [items, q],
  );

  useEffect(() => {
    if (open) {
      setQ('');
      setSel(0);
    }
  }, [open]);

  if (!open) return null;
  const go = (i?: NavItem) => {
    if (!i) return;
    nav(i.to);
    onClose();
  };

  return (
    <div className="ck" onClick={onClose}>
      <div className="ckb" onClick={(e) => e.stopPropagation()}>
        <input
          autoFocus
          placeholder="Jump to…"
          value={q}
          onChange={(e) => {
            setQ(e.target.value);
            setSel(0);
          }}
          onKeyDown={(e) => {
            if (e.key === 'ArrowDown') setSel((s) => Math.min(s + 1, list.length - 1));
            if (e.key === 'ArrowUp') setSel((s) => Math.max(s - 1, 0));
            if (e.key === 'Enter') go(list[sel]);
            if (e.key === 'Escape') onClose();
          }}
        />
        <div className="ckl">
          {list.map((i, idx) => (
            <div
              key={i.to}
              className={`cki ${idx === sel ? 's' : ''}`}
              onMouseEnter={() => setSel(idx)}
              onClick={() => go(i)}
            >
              <span className="ic">{i.icon}</span>
              {i.label}
              <span className="tg2">Go to</span>
            </div>
          ))}
          {!list.length && <div className="emp">No matches</div>}
        </div>
      </div>
    </div>
  );
}
