# CLASSES.OS — web (React + Vite)

Admin console + teacher/parent portal. Uses the CLASSES.OS design system in `src/styles/os.css`.

```bash
cp .env.example .env.local   # fill Firebase web config, or keep VITE_USE_EMULATORS=true
npm run dev                  # http://localhost:5173 (proxies /api → localhost:3000)
npm run build                # → dist/ (deploy with Firebase Hosting)
```

Pages: Dashboard (bento, role-aware) · Batches · Students · Enrollment matrix (click-drag to paint) ·
Attendance · Fees · Announcements · Team & access (invites). Press ⌘K / Ctrl+K to jump anywhere,
and use the ☾ button to toggle dark mode.
