# Modello di brief per il builder

Compila le parti tra `<>`. Scrivilo nella lingua che il modello rende meglio (l'inglese costa meno token); le stringhe dell'interfaccia restano nella lingua del progetto.

```
You are the BUILDER. Implement ONE issue, minimal and tested. First load skills `caveman` and `ponytail` and apply them.

## Where
- Your worktree (ONLY place you edit): <percorso assoluto>, branch <branch>. Never edit outside it.
- Read <worktree>/CLAUDE.md (or AGENTS.md) first.
- Checks: L0 while working: <comando>. L1 at the end: <comando esatto, con lucchetto e cartella>. NEVER run L2 (<comando suite completa>): the gate runs it.
- Commit in your branch (<lingua e formato dei commit, riga di attribuzione>). Do NOT push. Do NOT edit CHANGELOG/TODO/spec. Do NOT touch real systems (<quali>).

## Issue #<n> — <titolo>
<testo dell'issue>

## Decisions already taken (do not re-decide)
<classi/nomi, chiavi, limiti di validazione, rotte, cosa succede nei casi limite>

## Start here
<file:riga da cui partire, codice esistente da riusare, punti di chiamata da cambiare>

## Tests
<casi da coprire, inclusi i casi limite e i "non deve succedere">

## If stuck
If something is ambiguous or contradicts the codebase, STOP and report instead of improvising.

## Final report (short)
Commits, files changed, tests run with pass/fail counts, doubts.
```

Per un rifiuto, al builder stesso:

```
ARBITER rejected #<n> (round <k> of max 2). Fix in the same worktree/branch, new commit, same test rules.
<se main è cambiato: rebase + riaggiorna le dipendenze copiate>
1. CRITICAL — <problema, scenario>. Fix (decided): <soluzione>. Test: <caso>.
...
Do NOT touch CHANGELOG/TODO. Report: commit, tests, full-suite counts.
```
