# agent-customer-feedback

Un agente de Claude Code que recopila feedback de todos tus clientes desde cuatro fuentes (Slack Connect, Granola, Gmail, Notion), lo analiza y te envía un DM en Slack con bugs, feature requests y preguntas frecuentes clasificados por cliente.

## ¿Qué hace?

Ejecutás un comando en Claude Code y recibís automáticamente en tu Slack:

```
🔍 Feedback Clientes — últimos 7 días
_3 clientes · 4 fuentes · 12 señales totales_

━━━━━━━━━━━━━━━
*Cliente A*
🐛 Bugs
• Corregir error 500 en endpoint /payments al enviar monto con decimales

✨ Feature requests
• Implementar webhook de confirmación de pago con retry automático (Slack + reunión)

━━━━━━━━━━━━━━━
*Cliente B*
❓ Preguntas frecuentes
• Documentar en la API el comportamiento del campo `reference_id` cuando es nulo
```

Los clientes se descubren automáticamente desde los canales Slack Connect de tu workspace.

## Prerequisitos

- [Claude Code](https://claude.ai/code) instalado
- [Granola](https://granola.ai) instalado (para transcripciones de reuniones)
- `jq` instalado (`brew install jq`)
- Cuenta Claude.ai con las siguientes integraciones activas:
  - Slack
  - Gmail
  - Google Drive
  - Notion

## Instalación

```bash
git clone https://github.com/fidimoney/agent-customer-feedback.git
cd agent-customer-feedback
bash setup.sh
```

El script te va a pedir:
- **Company name**: el nombre de tu empresa tal como aparece en los canales Slack Connect (ej. `acme`, `fidi`)
- **Tu email de Slack**: para identificarte como destinatario del DM
- **Tu Slack user ID**: se encuentra en Slack → tu foto de perfil → Ver perfil → Más (•••) → Copiar ID de miembro

Para activar las integraciones de Claude.ai que no estén configuradas:
1. Abrí [Claude.ai → Settings → Integrations](https://claude.ai/settings?tab=integrations)
2. Conectá Slack, Gmail, Google Drive y Notion
3. Volvé a correr `bash setup.sh` para verificar

## Uso

Abrí Claude Code en cualquier directorio y ejecutá:

```
/feedback-clientes
```

Argumentos opcionales:

| Argumento | Descripción | Ejemplo |
|---|---|---|
| `[días]` | Analiza solo los últimos N días | `/feedback-clientes 7` |
| `--max-clients N` | Limita el análisis a N clientes | `/feedback-clientes --max-clients 5` |
| Combinados | N días + límite de clientes | `/feedback-clientes 7 --max-clients 3` |

Sin argumentos analiza todo el historial disponible.

### Primera vez: verificar conexiones

```
/fidi-setup
```

Este wizard ejecuta `setup.sh` y luego verifica que cada integración responda correctamente antes de tu primer análisis.

## Fuentes de datos

Por cada cliente (canal Slack Connect detectado automáticamente):

| Fuente | Qué captura |
|---|---|
| **Slack** | Mensajes del canal del cliente, archivos adjuntos, canvases |
| **Granola** | Transcripciones de reuniones donde participó el cliente |
| **Gmail** | Threads de email con el cliente |
| **Notion** | Páginas de notas, requerimientos, feedback explícito |

## Estructura del proyecto

```
.
├── setup.sh                          # Instalador (configura MCPs + identidad)
├── tests/
│   └── setup.bats                    # Tests del instalador
└── .claude/
    └── skills/
        ├── feedback-clientes/
        │   └── SKILL.md              # Skill principal del agente
        └── fidi-setup/
            └── SKILL.md              # Wizard de configuración
```

## Tests

```bash
brew install bats-core
bats tests/setup.bats
```

## Configuración

El agente guarda tu identidad en `~/.fidi-feedback/config.json`:

```json
{
  "slack_email": "tu@empresa.com",
  "slack_user_id": "U0XXXXXXX",
  "company_name": "acme"
}
```

Podés editarlo directamente o volver a correr `bash setup.sh`.

## Licencia

MIT
