# Vibetodo Roadmap

Structured around the 5 GTD Steps: **Capture → Clarify → Organize → Reflect → Engage**

Live at: https://vibetodo.fly.dev

---

## 1. Capture
*Collect what has your attention*

### Inbox ✓ — Vibetodo-3vk
- [x] Rename todo list to "Inbox"
- [x] Keyboard shortcut for rapid capture (`/` to focus)
- [x] Minimal friction: title only, process later
- [ ] Mobile-friendly quick add

---

## 2. Clarify
*Process what each item means*

### Processing Workflow ✓ — Vibetodo-b2c
- [x] "Process" mode to work through inbox items one by one
- [x] Decision tree: Delete / Done / Next Action / Someday/Maybe / Delegate / Assign to Project
- [x] Two-minute rule prompt ("Done" for quick tasks)
- [x] Skip option for items needing more thought

### Two-Minute Rule — Vibetodo-ihn
- [ ] Estimated time field
- [ ] Filter for quick wins (< 2 minutes)
- [ ] Visual indicator for quick tasks

---

## 3. Organize
*Put items where they belong*

### Projects ✓ — Vibetodo-mm8
- [x] Project schema (multi-step outcomes)
- [x] Link todos to projects
- [x] Project list with completion progress
- [x] Sidebar navigation

### Next Actions ✓ — Vibetodo-mjs
- [x] Star toggle to mark next actions
- [x] Sidebar view with count
- [x] Filter for actionable items only

### Waiting For ✓ — Vibetodo-x0o
- [x] "Waiting For" field for delegated items
- [x] Track who you're waiting on
- [x] Date delegated for follow-up
- [x] Sidebar view with count

### Someday/Maybe ✓ — Vibetodo-n2b
- [x] Someday/Maybe list for uncommitted items
- [x] Mark items during processing
- [x] Sidebar view with count

### Contexts (@tags) — Vibetodo-w0t (P4 - Backlog)
- [ ] Context tags (@home, @work, @phone, @computer, @errands)
- [ ] Filter by context
- [ ] Custom context creation

### Calendar & Tickler — Vibetodo-egp
- [ ] Due dates with time
- [ ] Tickler items (hide until date)
- [ ] Calendar view of scheduled items

### Reference Material — Vibetodo-a1l
- [ ] Notes field for todos
- [ ] File/link attachments
- [ ] Searchable reference archive

---

## 4. Reflect
*Review frequently*

### Weekly Review — Vibetodo-u5y
- [ ] Review dashboard showing all lists
- [ ] Guided review flow:
  - Clear inbox to zero
  - Review each project for next actions
  - Check Waiting For items
  - Review Someday/Maybe
- [ ] "Last reviewed" timestamp per project
- [ ] Stale item warnings

### Daily Review — Vibetodo-e56
- [ ] Morning planning view
- [ ] "Today" focus list
- [ ] End-of-day review prompt

---

## 5. Engage
*Choose and do*

### Focus Mode — Vibetodo-9sh
- [ ] Single-task view
- [ ] Timer integration (Pomodoro-style)
- [ ] "What's next?" suggestion based on context

---

## Infrastructure

### Deployment ✓
- [x] Fly.io deployment (Vibetodo-101)
- [x] SQLite with persistent volume
- [x] Production configuration

### CI/CD ✓ — Vibetodo-835
- [x] GitHub Actions for testing
- [x] Auto-deploy on main push
- [x] Health check endpoint (`/api/health`)

### Monitoring — Vibetodo-4a7
- [ ] Error tracking (Sentry)
- [ ] Log aggregation
- [ ] Application metrics

### Database — Vibetodo-3tf (P4 - Backlog)
- [ ] Migrate to PostgreSQL (when needed)

### Mobile — Vibetodo-2qx
- [ ] Responsive design
- [ ] PWA support
- [ ] Touch-friendly UI

---

## Progress Summary

| Phase | Status |
|-------|--------|
| **Phase 1 - Core Loop** | ✓ Complete |
| **Phase 2 - Full GTD** | ✓ Complete (Contexts deprioritized) |
| **Phase 3 - Review & Engage** | Not started |
| **Phase 4 - Polish** | Not started |

### Completed Features
1. ✓ Inbox (Capture)
2. ✓ Projects (Organize)
3. ✓ Next Actions (Organize)
4. ✓ Processing Workflow (Clarify)
5. ✓ Waiting For (Organize)
6. ✓ Someday/Maybe (Organize)
7. ✓ CI/CD Pipeline (Infrastructure)

### Next Up (P3)
- Weekly Review
- Daily Review
- Focus Mode
- Two-Minute Rule helpers
