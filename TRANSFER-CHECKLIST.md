# Repo Transfer Checklist

When a repo is transferred from **ZoneCNH** → **xhyperium**, complete these steps:

## 1. GitHub Transfer
- [ ] Transfer via `gh api` or GitHub UI (`org/repo` → `xhyperium/repo`)
- [ ] Verify new URL resolves: `gh api repos/xhyperium/{repo}`
- [ ] Verify old URL 301 redirects

## 2. Update xhyperium/.github Profile
- [ ] Edit `profile/README.md` — change the module link from `ZoneCNH/{repo}` to `xhyperium/{repo}`
- [ ] Commit: `docs: {module} 链接 ZoneCNH → xhyperium`
- [ ] Push to `main`

## 3. Update ZoneCNH Docs Hub
- [ ] `module/registry.yaml` — update `repo` and `owner` fields
- [ ] `module/FOUNDATION-DEPS.yaml` — update any references
- [ ] Global string replacement: `rg -l 'ZoneCNH/{repo}'` → sed replace
- [ ] Update `docs/migrations/{module}-ALIGNMENT-SYNC.md`

## 4. Update Local Runtime Remote
- [ ] `cd /home/workspace/{repo} && git remote set-url origin git@github.com:xhyperium/{repo}.git`
- [ ] Verify: `git ls-remote --quiet origin HEAD`

## 5. Verification (20-round agent audit)
- [ ] Full tree scan for `ZoneCNH/{repo}` → NONE
- [ ] Registry, DEPS, alignment doc all point to xhyperium
- [ ] All 20 agents PASS

## Transferred Repos

| Repo | Date | Verified |
|------|------|----------|
| binance | 2026-07-11 | 20/20 PASS |
