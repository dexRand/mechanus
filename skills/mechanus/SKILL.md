---
name: mechanus
description: >
  Metodo di lavoro per issue: l'orchestratore (tu) intervista, scrive issue e brief,
  delega la build a un builder economico in un worktree e la verifica a un arbitro
  forte a contesto pulito, poi unisce una PR alla volta. Usa quando l'utente chiede
  di lavorare una o più issue con i subagenti, "builder e arbitro", "mechanus",
  "fallo fare a sonnet", o di avviare una funzionalità o un progetto nuovo da
  spezzare in issue. Vale in Claude Code e in OpenCode.
---

# Mechanus: issue → builder → arbitro → PR

Tu sei l'**orchestratore**: parli con l'utente, decidi, scrivi i brief, unisci. Non scrivi il codice delle issue delegate; tieni il tuo contesto piccolo.

| Ruolo | Chi | Claude Code | OpenCode |
|---|---|---|---|
| Orchestratore | tu | sessione principale | agente primario |
| Builder | modello economico | agente `builder` (`claude/agents/builder.md`, Sonnet), in background | ASU-001 (flash), tool `subagent`: sempre in background |
| Arbitro | modello forte, **diverso dal builder** (meglio un'altra famiglia: non dà ragione a se stesso), contesto pulito | agente `arbiter` (`claude/agents/arbiter.md`, Opus), in background | ARBITER (pro); `edit` negato nei `permissions` |
| Occhi (RECON) | modello **con visione**: guarda screenshot e riporta a parole, non edita | non serve: l'orchestratore vede le immagini | RECON (flash); `edit` negato nei `permissions` |

**Vincolo di modello per RECON:** non tutti i modelli hanno la visione. `deepseek-v4-pro` (orchestratore e arbitro in OpenCode) è solo testo; `deepseek-flash` ha la visione. RECON **deve** stare su un modello con visione, e non va assunto: prima di affidarle un lavoro (e ogni volta che cambi il suo modello) **verifica** con un'immagine di prova che descriva cose che il testo non può sapere (colori, posizione degli elementi). Se risponde in modo vago o generico, il modello non vede.

### Agenti specializzati
Un agente nuovo (builder o arbitro) si crea **solo se cambia qualcosa che un prompt non può cambiare**: il **modello** (es. visione, più forte per i dati, più economico per i testi), gli **strumenti/permessi** (es. `bin/screenshot.sh`, `edit` negato) o i **tetti** (`steps`, lucchetti). RECON è il caso tipico: esiste perché ha un modello diverso.
- Tutto il resto (convenzioni, checklist di un tipo di lavoro) va in una **skill** o nel brief, non in una "personalità": lo stesso modello con un'altra persona resta lo stesso modello, e N prompt da tenere allineati divergono.
- Il nome dice la funzione (`ASU-UI`, `ARBITER-SEC`), non un numero: l'orchestratore sceglie anche dal nome.
- Il prompt dello specialista contiene **solo la differenza**; le regole comuni (non pushare, niente L2, niente CHANGELOG) restano in questa skill.
- La specializzazione rende di più in **revisione**: un arbitro con una checklist stretta (sicurezza, dati) trova ciò che uno generico salta.
- **Uno alla volta, misurato**: un nuovo specialista lavora circa 10 issue della sua etichetta; confronta con il generalista token, giri dell'arbitro ed esito (§9). Se non vince, si toglie. Se resta, aggiungi la sua riga nella tabella del §3.

Senza gli agenti installati, in Claude Code va bene anche `Agent` generico con `model: sonnet` / `model: opus`.

Per rimandare un lavoro allo stesso agente col suo contesto: `SendMessage` (Claude Code) o il tool `subagent` con lo stesso `sessionID` (OpenCode).

Tetti veri, non solo istruzioni: in OpenCode `steps` per agente (es. ASU 80, ARBITER 50) e `permissions` (`edit` negato all'arbitro); in Claude Code l'arbitro ha il divieto nel prompt e il lavoro è comunque in un worktree separato.

## 1. Intervista (solo se serve)
- Progetto o funzionalità nuova, o richiesta vaga → skill `interview-me` prima di tutto: una domanda alla volta finché sai **cosa**, **per chi** e **quando è fatto**.
- Issue già concreta → salta.

## 2. Issue
Ogni pezzo di lavoro è un'issue con: cosa, perché, criterio di «fatto», vincoli (cosa NON fare). L'issue è la memoria: si riparte da lì.
- Le **decisioni di prodotto** (cosa è un errore, cosa si notifica, cosa si può cancellare) le prende l'utente o tu, mai il builder.
- Metti l'**etichetta** che decide chi la lavora (tabella nel §3). La decidi tu, una volta, quando scrivi l'issue.
- Rileggi il criterio di «fatto» con occhio cattivo: il builder lo eseguirà alla lettera, e i suoi test confermeranno anche un requisito sbagliato.

## 3. Smistamento
| Al builder | Restano a te |
|---|---|
| regola, pagina admin, endpoint, refactor con test | interfaccia e gusto (skill `impeccable`, screenshot) |
| lavoro verificabile con i test | scritture su sistemi veri, prove manuali, ambienti di prova |
| issue indipendenti → in parallelo | esplorazione di API sconosciute, decisioni |
| | ritocchi da poche righe (costano meno di un giro) |

### Chi lavora l'issue (per etichetta)
Lo smistamento lo decide l'etichetta scritta nell'issue, non un giudizio del momento. Senza etichetta: generalista.
| Etichetta | Builder | Arbitro | Note |
|---|---|---|---|
| *(nessuna)* | ASU-001 / `builder` | ARBITER / `arbiter` | il caso normale |
| `banale` | ASU-001 / `builder` | nessuno | testi, configurazione, poche righe senza logica; solo L1 |
| `area:ui` | ASU-001 / `builder` | ARBITER / `arbiter` + verifica visiva (RECON) | screenshot con `bin/screenshot.sh` |

Una riga nuova solo quando esiste davvero l'agente (vedi *Agenti specializzati*). Un'issue con due etichette va all'agente più cauto (arbitro incluso).

- **Verifica visiva → RECON** (OpenCode, dove l'orchestratore è solo testo): screenshot di una pagina, allineamenti, spaziature, testo tagliato o sovrapposto, contrasto, confronto con il layout atteso. Lo screenshot lo scatta chi ha la pagina in esecuzione (tu, o il builder se lo scrivi nel brief) con `bin/screenshot.sh <url> <file.png> [larghezza,altezza]` (Playwright in Docker); a RECON dai il **percorso del file** e cosa ci si aspetta; ti torna un elenco di discrepanze per gravità, che diventa la lista di correzioni per il builder. In Claude Code guardi tu lo screenshot. Il gusto e le decisioni restano a te: RECON osserva, non decide.

- **Issue banali** (etichetta `banale`: testi, configurazione, poche righe senza logica): builder e L1, **niente arbitro**. L'arbitro serve dove ci sono logica, dati o rischio: lì si ripaga.
- **Un file, un proprietario:** due issue che toccano gli stessi file non vanno in parallelo, si mettono in fila.
- **Git in fila:** le operazioni git sui worktree (rebase, commit di unione, push) le fai tu, una alla volta.

## 4. Worktree
Un worktree e un branch per issue (`git worktree add <dir> -b <tipo>/<n>-<slug> main`). Prima di lanciare, verifica che **i test girino nel worktree** con un test qualsiasi. Tranelli già visti:
- se i test girano in un container, il worktree deve stare **dentro** la cartella montata;
- le dipendenze installate (es. `vendor/`) vanno **copiate** (`cp -al`, hardlink: niente spazio), non collegate: col link l'autoload carica il codice della cartella principale;
- `.env` e build degli asset si possono collegare;
- un solo database di test → ogni comando di test sotto lo stesso lucchetto (`flock <file> <comando>`);
- l'hook di pre-push deve verificare il worktree, non la cartella principale.
Se il progetto ha una sezione su worktree e test nel suo CLAUDE.md/AGENTS.md, segui quella.

## 4-bis. Livelli di verifica
Il CLAUDE.md/AGENTS.md del progetto dice quali comandi sono L0, L1, L2. Se non lo dice, chiedilo all'utente e scrivilo lì.
| Livello | Cosa | Durata | Chi |
|---|---|---|---|
| L0 | lint, tipi, stile, build | secondi | builder, mentre lavora |
| L1 | i test di ciò che si tocca (filtro, cartella, «affected») | minuti | builder alla fine; arbitro con le sue prove |
| L2 | suite completa, e2e, integrazione | minuti… ore | **una volta per PR**: pre-push se è corto, **CI** se è lungo |
- Builder e arbitro **non lanciano mai L2**. Gli output dei test sono la voce che pesa di più nel contesto: meno test, meno token.
- L2 lungo (oltre ~15 minuti): il pre-push lancia solo L1, il gate vero è la CI. **Nessun modello aspetta la CI**: aspetta uno script (`gh pr checks --watch`, zero token). Se fallisce, allo stesso builder arriva **solo la coda del log**; contatore a parte, massimo 2, poi l'utente.
- Test instabili: un solo nuovo tentativo del test fallito prima di incolpare il builder.

## 5. Builder
Brief da [brief-builder.md](brief-builder.md). Il brief è tutto ciò che sa: file da cui partire, decisioni già prese, comandi esatti, divieti. Skill per il builder: `caveman` + `ponytail`. Il builder committa nel suo branch, **non pusha**, **non tocca CHANGELOG/TODO/spec** (conflitti tra issue parallele: li aggiorni tu).

## 6. Arbitro
Brief da [brief-arbitro.md](brief-arbitro.md). Regole:
- contesto pulito: gli dai **l'issue e il codice, non le conclusioni del builder**;
- il compito è **smontare**: approva solo se non ci riesce;
- elenca dove scavare (avvio, dati mancanti, soglie che si incrociano, cicli su tutta la base dati, identità/duplicati, sicurezza);
- lancia L1 e le sue prove mirate e **misura** (tempi, query, conteggi); non la suite completa, che è un doppione;
- si chiede se i test fallirebbero togliendo la riga chiave;
- non edita e non committa.
Filtra le sue segnalazioni: alcune sono compito tuo (CHANGELOG) o già decise.

## 7. Ciclo
- Rifiuto → lista di correzioni **con le decisioni già prese** allo stesso builder (contesto intatto), poi all'arbitro stesso per il secondo giro.
- **Massimo 2 rifiuti**, poi ti fermi e lo porti all'utente.
- Dopo l'approvazione, i suggerimenti piccoli li applichi tu.

## 8. Unione (una PR alla volta)
1. Allinea il branch a `main` (rebase), riaggiorna le dipendenze copiate se `main` le ha cambiate.
2. CHANGELOG e TODO, commit, push, PR con: cosa, come è stata lavorata (giri dell'arbitro), rischi residui. Nel corpo della PR `Closes #<n>`.
3. L2: se è corto l'ha già fatto il pre-push; se è lungo **non aspettare**: passa all'issue successiva, il risultato della CI arriva dallo script.
4. Unita la PR: chiudi l'issue, togli il worktree e il branch.
Se la verifica si blocca per cause esterne (falle nelle dipendenze), PR separata prima.

## 9. Misura
Per ogni issue annota: token e tempo di builder e arbitro, giri dell'arbitro, giri della CI, esito, interventi dell'utente. Mettilo nel resoconto all'utente. Dopo una decina di issue si vede se il metodo conviene e dove.

## Regole che non si piegano
- Nessuna scrittura su sistemi veri da builder o arbitro; le regole del progetto valgono anche per loro (scrivile nel brief).
- Le regole che non devono mai saltare vanno in **controlli veri** (hook, lucchetti, contatori nello script), non solo nel testo: un modello debole può ignorarle.
- Resoconti all'utente brevi, in parole semplici: cosa è entrato, cosa ha respinto l'arbitro e perché, quanto è costato.
