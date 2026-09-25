import { ReactNode } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import { navFor } from './components/nav';
import { Shell } from './components/Shell';
import { Spinner } from './components/ui';
import { useAuth } from './lib/auth';
import { Announcements } from './pages/Announcements';
import { Attendance } from './pages/Attendance';
import { Batches } from './pages/Batches';
import { Dashboard } from './pages/Dashboard';
import { Enrollment } from './pages/Enrollment';
import { Fees } from './pages/Fees';
import { Login } from './pages/Login';
import { Members } from './pages/Members';
import { Onboarding } from './pages/Onboarding';
import { Students } from './pages/Students';

const PAGES: Record<string, ReactNode> = {
  '/': <Dashboard />,
  '/batches': <Batches />,
  '/students': <Students />,
  '/enrollment': <Enrollment />,
  '/attendance': <Attendance />,
  '/fees': <Fees />,
  '/announcements': <Announcements />,
  '/members': <Members />,
};

export function App() {
  const { user, me, loading } = useAuth();
  if (loading) return <Spinner />;
  if (!user) return <Login />;
  if (!me) return <Spinner />;
  if (!me.institute) return <Onboarding />;

  return (
    <Routes>
      <Route element={<Shell />}>
        {navFor(me.role).map((n) => (
          <Route key={n.to} path={n.to} element={PAGES[n.to]} />
        ))}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
