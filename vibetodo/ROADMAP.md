# Vibetodo Roadmap

Structured around the 5 GTD Steps: **Capture → Clarify → Organize → Reflect → Engage**

---

## 1. Capture
*Collect what has your attention*

### Inbox — Vibetodo-3vk
- [ ] Rename todo list to "Inbox"
- [ ] Keyboard shortcut for rapid capture (Ctrl+Enter / Cmd+Enter)
- [ ] Minimal friction: title only, process later
- [ ] Mobile-friendly quick add

---

## 2. Clarify
*Process what each item means*

### Processing Workflow — Vibetodo-b2c
- [ ] "Process" mode to work through inbox items one by one
- [ ] Decision tree: Is it actionable? → What's the next action? → Is it a project?
- [ ] Two-minute rule prompt: "Can you do this in 2 minutes?"

### Two-Minute Rule — Vibetodo-ihn
- [ ] Estimated time field
- [ ] Filter for quick wins (< 2 minutes)
- [ ] Visual indicator for quick tasks
- [ ] "Do it now" prompt during clarify

---

## 3. Organize
*Put items where they belong*

### Projects — Vibetodo-mm8
- [ ] Project schema (multi-step outcomes)
- [ ] Link todos to projects
- [ ] Project list with completion progress
- [ ] Next action indicator per project

### Contexts (@tags) — Vibetodo-w0t
- [ ] Context tags (@home, @work, @phone, @computer, @errands)
- [ ] Filter by context
- [ ] Custom context creation

### Next Actions — Vibetodo-mjs
- [ ] Distinguish "next actions" from other todos
- [ ] Every project needs at least one next action
- [ ] Quick filter for actionable items

### Waiting For — Vibetodo-x0o
- [ ] "Waiting For" status for delegated items
- [ ] Track who/what you're waiting on
- [ ] Date delegated for follow-up

### Someday/Maybe — Vibetodo-n2b
- [ ] Someday/Maybe list for uncommitted items
- [ ] Move items between Inbox ↔ Someday/Maybe
- [ ] Periodic review prompts

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

### Context Views — Vibetodo-w0t
- [ ] "@work" view shows only work tasks
- [ ] "@home" view shows only home tasks
- [ ] Location/energy/time-based filtering

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

### CI/CD — Vibetodo-835
- [ ] GitHub Actions for testing
- [ ] Auto-deploy on main push
- [ ] Health check endpoint

### Monitoring — Vibetodo-4a7
- [ ] Error tracking (Sentry)
- [ ] Log aggregation
- [ ] Application metrics

### Database — Vibetodo-3tf
- [ ] Migrate to PostgreSQL (when needed)

### Mobile — Vibetodo-2qx
- [ ] Responsive design
- [ ] PWA support
- [ ] Touch-friendly UI

---

## Implementation Order

**Phase 1 - Core Loop**
1. Capture: Inbox (Vibetodo-3vk)
2. Organize: Projects (Vibetodo-mm8)
3. Organize: Next Actions (Vibetodo-mjs)

**Phase 2 - Full GTD**
4. Clarify: Processing Workflow (Vibetodo-b2c)
5. Organize: Contexts (Vibetodo-w0t)
6. Organize: Waiting For (Vibetodo-x0o)
7. Organize: Someday/Maybe (Vibetodo-n2b)

**Phase 3 - Review & Engage**
8. Reflect: Weekly Review (Vibetodo-u5y)
9. Engage: Focus Mode (Vibetodo-9sh)
10. Reflect: Daily Review (Vibetodo-e56)

**Phase 4 - Polish**
11. Clarify: Two-Minute Rule (Vibetodo-ihn)
12. Organize: Calendar & Tickler (Vibetodo-egp)
13. Organize: Reference Material (Vibetodo-a1l)
