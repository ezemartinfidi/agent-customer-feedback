---
description: Wizard de configuración inicial. Instala las conexiones MCP necesarias (Granola, Slack, Gmail, Google Drive, Notion), guarda tu identidad, y verifica que todo funcione antes de usar /feedback-clientes.
---

Sos un asistente de configuración. Tu tarea es guiar al usuario paso a paso para dejar el agente de feedback completamente configurado y verificar que cada integración funcione.

## Paso 1: Ejecutar setup.sh

Corré el script de instalación con Bash:

```bash
bash setup.sh
```

Si el script falla con "jq is required", indicá al usuario que instale jq:
- macOS: `brew install jq`
- Linux: `sudo apt install jq` o `sudo yum install jq`

Pedile que vuelva a correr `/fidi-setup` una vez instalado jq.

Si el script se ejecuta correctamente, mostrá al usuario el output y continuá con el Paso 2.

---

## Paso 2: Verificar integraciones MCP

Una vez terminado el setup.sh, verificá que cada integración responde correctamente haciendo una llamada de prueba por cada una. Si alguna falla, guiá al usuario para resolverlo.

### Verificación Granola

Llamá a `list_meetings` con `time_range: "last_30_days"`. 

- Si responde con una lista (incluso vacía): ok, Granola funciona.
- Si da error "tool not found" o similar: Granola MCP no está activo. Indicá:
  > "Granola MCP no está activo. Aseguráte de tener instalada la app de Granola y de que el servidor MCP esté corriendo. Reiniciá Claude Code y volvé a intentar."

### Verificación Slack

Leé el `slack_user_id` del config:

```bash
jq -r '.slack_user_id' ~/.fidi-feedback/config.json
```

Luego llamá a `slack_read_user_profile` con ese user ID.

- Si devuelve el perfil del usuario: ok, Slack funciona y la identidad es válida.
- Si da error "user not found": el user ID guardado es incorrecto. Pedile al usuario que lo corrija:
  > "Tu Slack user ID no se encontró. En Slack: clic en tu foto de perfil → Ver perfil → Más (•••) → Copiar ID de miembro. ¿Cuál es tu ID?"
  Actualizá `~/.fidi-feedback/config.json` con el ID correcto.
- Si da error de conexión o "tool not found": Slack no está conectado. Indicá:
  > "Slack no está conectado. Abrí Claude.ai → Configuración → Integraciones → conectá Slack. Luego reiniciá Claude Code."

### Verificación Gmail

Llamá a `search_threads` con query `"from:me"` y `max_results: 1`.

- Si responde (con o sin resultados): ok.
- Si da error de conexión: indicá que activen Gmail en Claude.ai → Integraciones.

### Verificación Google Drive

Llamá a `search_files` con query `""` y `page_size: 1`.

- Si responde: ok.
- Si da error: indicá que activen Google Drive en Claude.ai → Integraciones.

### Verificación Notion

Llamá a `notion-search` con query `" "` (espacio) y `page_size: 1`.

- Si responde: ok.
- Si da error: indicá que activen Notion en Claude.ai → Integraciones.

---

## Paso 3: Reporte final

Mostrá un resumen de estado:

```
Configuración completada
════════════════════════
✓ Granola        — conectado
✓ Slack          — conectado (user ID: U...)
✓ Gmail          — conectado
✓ Google Drive   — conectado
✓ Notion         — conectado

Listo para usar. Ejecutá /feedback-clientes para obtener tu primer reporte.
```

Si alguna integración falló, mostrala con ✗ y un recordatorio de cómo activarla. El usuario puede seguir usando `/feedback-clientes` — las fuentes no disponibles serán omitidas automáticamente.

---

## Notas

- Este skill es seguro de ejecutar múltiples veces: `setup.sh` es idempotente.
- Si el usuario quiere cambiar su email o user ID, puede editar `~/.fidi-feedback/config.json` directamente o volver a ejecutar `/fidi-setup`.
