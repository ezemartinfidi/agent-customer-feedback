# Customer Feedback Agent — Monnet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a `/feedback-monnet` Claude Code slash command that collects signals from Slack `#monnet-fidi`, Granola meeting transcripts, and Gmail, classifies them into Bugs / Feature requests / Preguntas, and delivers a formatted Slack DM to @ezequiel.martin.

**Architecture:** A single Claude Code custom command file (`.claude/commands/feedback-monnet.md`) containing a structured prompt. When invoked, Claude uses available MCP tools to collect data, performs a synthesis pass, and sends the DM. No external dependencies — relies entirely on MCPs already configured in the session (Slack, Granola, Gmail).

**Tech Stack:** Claude Code custom commands · Slack MCP (`plugin_slack`) · Granola MCP · Gmail MCP (`claude_ai_Gmail`)

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `.claude/commands/feedback-monnet.md` | Create | The slash command prompt |
| `.gitignore` | Create | Exclude `.superpowers/` and other non-tracked dirs |

---

## Task 1: Initialize project

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: Initialize git repo**

```bash
git init
```

Expected: `Initialized empty Git repository in .git/`

- [ ] **Step 2: Create .gitignore**

Create `.gitignore` with this content:

```
.superpowers/
.claude/settings.local.json
```

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: init project with gitignore"
```

---

## Task 2: Write the /feedback-monnet command

**Files:**
- Create: `.claude/commands/feedback-monnet.md`

- [ ] **Step 1: Create the commands directory**

```bash
mkdir -p .claude/commands
```

- [ ] **Step 2: Write the command file**

Create `.claude/commands/feedback-monnet.md` with this exact content:

```markdown
Sos un agente de análisis de feedback de clientes de Fidi. Tu tarea es recopilar todas las señales del cliente **Monnet** desde tres fuentes, analizarlas y enviarme un DM en Slack con el resultado.

## Scope temporal

- Si `$ARGUMENTS` es "all" o no hay argumento → recopilá TODO el historial disponible
- Si `$ARGUMENTS` es un número (ej. "7") → últimos N días desde hoy

Por defecto (sin argumento): historial completo.

## Paso 1: Recopilación de datos

Ejecutá estas tres recopilaciones antes de analizar nada.

### Fuente A — Slack: canal #monnet-fidi

1. Usá `slack_search_channels` para encontrar el canal con nombre "monnet-fidi" y obtener su ID
2. Usá `slack_read_channel` para leer todos los mensajes del canal (pasá el channel ID y un límite alto, ej. 200)
3. Si en los mensajes hay canvases o documentos adjuntos, leelos con `slack_read_canvas`

### Fuente B — Granola: reuniones con Monnet

1. Usá `query_granola_meetings` con query "monnet" para encontrar todas las reuniones relevantes
2. Para cada reunión encontrada, usá `get_meeting_transcript` con su ID para obtener el transcript completo
3. Si no encontrás resultados con "monnet", probá con "Monnet" (mayúscula)

### Fuente C — Gmail: emails con Monnet

1. Usá `search_threads` con query `monnet` para encontrar threads relevantes
2. Para los primeros 10 threads encontrados, usá `get_thread` para leer el contenido completo
3. Si hay más de 10 threads, priorizá los más recientes

## Paso 2: Análisis

Con todo el contenido recopilado, hacé UNA pasada de síntesis:

1. **Descartá ruido**: saludos, coordinación de agendas, mensajes off-topic, conversaciones internas del equipo Fidi sin señales de cliente
2. **Deduplicá**: si el mismo problema aparece en múltiples fuentes, es UN solo item
3. **Clasificá** cada señal en una de estas tres categorías:
   - 🐛 **Bugs / errores**: algo que no funciona como debería o que da error
   - ✨ **Feature requests**: funcionalidad que piden y no existe aún
   - ❓ **Preguntas frecuentes**: dudas recurrentes que sugieren UX poco clara o documentación faltante
4. **Marcá frecuencia**: si un item aparece en múltiples fuentes, agregá al final del bullet: `(Slack + reunión)`, `(email + Slack)`, etc.

## Paso 3: Envío del DM

1. Usá `slack_search_users` con query "ezequiel martin" para obtener el user ID de @ezequiel.martin
2. Usá `slack_send_message` con el user ID como canal (los DMs en Slack se envían usando el user ID como channel) y este mensaje formateado:

```
🔍 *Feedback Monnet — [indicá el período analizado, ej. "todo el historial" o "1–7 may 2026"]*
_[N] fuentes · [N] señales analizadas_

*Bugs / errores reportados*
• [descripción concreta del problema, máx 15 palabras]
• ...

*Feature requests*
• [descripción concreta del pedido, máx 15 palabras]
• ...

*Preguntas frecuentes*
• [pregunta o tema concreto, máx 15 palabras]
• ...
```

**Reglas para los bullets:**
- Concretos y específicos — sin resúmenes vagos como "problemas con la plataforma"
- Máximo ~15 palabras por bullet
- Omitir categorías que no tengan items
- Si un item viene de múltiples fuentes, agregar la referencia al final: `(Slack + reunión)`
- Escribí en español
```

- [ ] **Step 3: Verify the file exists and looks correct**

```bash
cat .claude/commands/feedback-monnet.md
```

Expected: the full prompt content printed to stdout.

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/feedback-monnet.md
git commit -m "feat: add /feedback-monnet slash command"
```

---

## Task 3: First run — full Monnet history

This task validates the command works and produces useful output. There are no automated tests for a prompt file — the validation is qualitative.

- [ ] **Step 1: Run the command**

In Claude Code terminal, type:

```
/feedback-monnet
```

(No arguments → defaults to full history as per the command logic.)

- [ ] **Step 2: Verify data collection**

While Claude runs, watch for:
- It finds and reads `#monnet-fidi` channel messages ✓
- It reads the attached document in the channel ✓
- It finds Granola meetings with Monnet ✓
- It reads Gmail threads with Monnet ✓

If any source returns 0 results, investigate before proceeding (the MCP may need a different search query).

- [ ] **Step 3: Check the DM**

Open Slack and check the DM from the bot. Evaluate:
- Is the classification accurate? (bugs are really bugs, not features)
- Are bullets concrete and specific, not vague?
- Are there obvious signals missing from the output?
- Are there false positives (noise classified as signal)?

- [ ] **Step 4: If output quality is acceptable → document next steps**

If the DM looks good, you're ready to:
1. Activate the weekly cron: use `/schedule` skill to run `/feedback-monnet 7` every Monday
2. Add Jira ticket creation: extend the command with a Step 4 that creates tickets for bugs and feature requests

If output needs refinement, adjust the analysis instructions in `.claude/commands/feedback-monnet.md` and re-run.

---

## Notes for later iterations

**Activating the weekly cron:** Use the `/schedule` skill with prompt `/feedback-monnet 7` and schedule `every Monday at 9am`.

**Adding Jira tickets:** Extend Step 3 of the command to create one Jira issue per bug and feature request using `mcp__plugin_atlassian_atlassian__createJiraIssue` with project key TBD.

**Adding more clients:** Duplicate `.claude/commands/feedback-monnet.md` to `.claude/commands/feedback-<cliente>.md` and update client name, Slack channel, and email search query.
