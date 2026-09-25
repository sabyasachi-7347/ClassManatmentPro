import { useEffect, useState } from 'react';
import { NavLink, Outlet } from 'react-router-dom';
import { useAuth } from '../lib/auth';
import { CommandPalette } from './CommandPalette';
import { navFor } from './nav';
import { useTheme } from './theme';

export function Shell() {
  const { me, logout } = useAuth();
  const { theme, toggle } = useTheme();
  const [ck, setCk] = useState(false);
  const [menu, setMenu] = useState(false);
  const items = navFor(me?.role);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        setCk((v) => !v);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  return (
    <>
      <header className="cr">
        <button className="tm menu-btn" onClick={() => setMenu((v) => !v)} aria-label="Menu">☰</button>
        <div className="bd">CLASSES<em>.OS</em></div>
        <div className="rgt">
          <span className="kk" onClick={() => setCk(true)}>
            Search <b>⌘K</b>
          </span>
          <button className="tm" onClick={toggle} aria-label="Toggle theme">
            {theme === 'dark' ? '☀' : '☾'}
          </button>
          <button className="tm" onClick={logout} aria-label="Sign out" title="Sign out">⎋</button>
        </div>
      </header>
      <div className="sh">
        <nav className={`sd ${menu ? 'open' : ''}`}>
          <div className="sdh">
            <div className="i">{me?.institute?.name}</div>
            <div className="r">{me?.role}</div>
          </div>
          {items.map((n) => (
            <NavLink
              key={n.to}
              to={n.to}
              end={n.to === '/'}
              className={({ isActive }) => `nv ${isActive ? 'on' : ''}`}
              onClick={() => setMenu(false)}
            >
              <span className="ic">{n.icon}</span>
              {n.label}
            </NavLink>
          ))}
        </nav>
        <main className="mn">
          <Outlet />
        </main>
      </div>
      <CommandPalette items={items} open={ck} onClose={() => setCk(false)} />
    </>
  );
}
