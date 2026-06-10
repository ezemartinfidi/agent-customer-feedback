# Contributing

## Cómo contribuir

Las contribuciones más útiles son:
- **Nuevas fuentes de datos**: agregar soporte para Intercom, HubSpot, Linear, etc.
- **Mejoras al prompt**: casos edge que el agente maneja mal
- **Tests para `setup.sh`**: nuevos escenarios en `tests/setup.bats`
- **Documentación**: traducciones, ejemplos, guías

## Setup local

```bash
git clone https://github.com/ezemartinfidi/agent-customer-feedback.git
cd agent-customer-feedback
bash setup.sh
```

Para correr los tests del instalador:
```bash
brew install bats-core
bats tests/setup.bats
```

## Estructura

```
.claude/skills/[skill-name]/SKILL.md   # prompt del skill — texto plano
setup.sh                               # instalador bash
tests/setup.bats                       # tests del instalador
```

Los skills son archivos markdown puros. Para editar el comportamiento del agente, editá el `.md` correspondiente y probá en Claude Code con `/feedback-clientes [args]`.

## Pull requests

1. Fork + rama descriptiva (`feat/intercom-source`, `fix/granola-filter`)
2. Si modificás `setup.sh`, aseguráte de que los tests pasan: `bats tests/setup.bats`
3. Si agregás una nueva fuente, actualizá el README (tabla "Fuentes de datos")
4. PR con descripción de qué cambia y por qué

## Bugs

Usá el template de bug report. Incluí el output de `bash setup.sh` si el problema es de instalación.
