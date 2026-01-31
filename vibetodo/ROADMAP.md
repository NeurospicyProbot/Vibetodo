# Vibetodo Roadmap

## 1. Deploy the Code

### 1.1 Choose Hosting Platform
- [x] **Fly.io** - Deployed ✓ (Vibetodo-101)

### 1.2 Production Configuration
- [x] Configure `config/runtime.exs` for production secrets ✓
- [x] Set up SSL/TLS certificates ✓ (Fly.io handles this)
- [x] Set up Fly.io persistent volume for SQLite ✓
- [x] Set `PHX_HOST` and `SECRET_KEY_BASE` environment variables ✓

### 1.3 Database Migration (Future) — Vibetodo-3tf
- [ ] Switch from SQLite to Postgres when needed (multi-device, redundancy)
- [ ] Options: Fly Postgres, Supabase, or Neon (all have free tiers)

### 1.4 CI/CD Pipeline — Vibetodo-835
- [ ] Add GitHub Actions workflow for automated testing
- [ ] Configure automatic deployment on main branch push
- [ ] Add health check endpoint

### 1.5 Monitoring & Logging — Vibetodo-4a7
- [ ] Set up error tracking (Sentry or similar)
- [ ] Configure log aggregation
- [ ] Add basic application metrics

---

## 2. Getting Things Done (GTD) Features

### 2.1 Inbox - Quick Capture — Vibetodo-3vk
- [ ] Rename current todo list to "Inbox"
- [ ] Add keyboard shortcut for rapid capture (Ctrl+Enter)
- [ ] Support for capturing with minimal friction (title only, process later)

### 2.2 Projects — Vibetodo-mm8
- [ ] Create Project schema (multi-step outcomes)
- [ ] Link todos to projects
- [ ] Project list view with completion progress
- [ ] "Next action" indicator per project

### 2.3 Contexts — Vibetodo-w0t
- [ ] Add context tags (@home, @work, @phone, @computer, @errands)
- [ ] Filter todos by context
- [ ] Custom context creation
- [ ] Context-based views for focused work

### 2.4 Next Actions — Vibetodo-mjs
- [ ] Distinguish between "next actions" and other todos
- [ ] Quick filter for actionable items only
- [ ] Ensure every project has at least one next action

### 2.5 Waiting For — Vibetodo-x0o
- [ ] "Waiting For" status for delegated items
- [ ] Track who/what you're waiting on
- [ ] Date delegated for follow-up

### 2.6 Someday/Maybe — Vibetodo-n2b
- [ ] Someday/Maybe list for non-committed items
- [ ] Move items between Inbox and Someday/Maybe
- [ ] Periodic review prompts

### 2.7 Reference Material — Vibetodo-a1l
- [ ] Notes field for todos
- [ ] File/link attachments
- [ ] Searchable reference archive

### 2.8 Weekly Review — Vibetodo-u5y
- [ ] Review dashboard showing all lists
- [ ] Guided review flow (check projects, clear inbox, review waiting)
- [ ] "Last reviewed" timestamp per project
- [ ] Stale item warnings

### 2.9 Calendar Integration — Vibetodo-egp
- [ ] Due dates with time
- [ ] "Tickler" items (hide until date)
- [ ] Calendar view of scheduled items

### 2.10 Two-Minute Rule — Vibetodo-ihn
- [ ] Estimated time field
- [ ] Filter for quick wins (< 2 minutes)
- [ ] Visual indicator for quick tasks

---

## Priority Order

**Phase 1 - Foundation**
1. ~~Deploy to Fly.io~~ ✓ (Vibetodo-101)
2. Add Projects (Vibetodo-mm8)
3. Add Contexts (Vibetodo-w0t)

**Phase 2 - Core GTD**
4. Inbox + Next Actions (Vibetodo-3vk, Vibetodo-mjs)
5. Waiting For list (Vibetodo-x0o)
6. Someday/Maybe list (Vibetodo-n2b)

**Phase 3 - Polish**
7. Weekly Review feature (Vibetodo-u5y)
8. Due dates and tickler (Vibetodo-egp)
9. Reference/notes system (Vibetodo-a1l)

**Phase 4 - Advanced**
10. Two-minute rule helpers (Vibetodo-ihn)
11. Calendar integration (Vibetodo-egp)
12. Mobile-friendly improvements (Vibetodo-2qx)
