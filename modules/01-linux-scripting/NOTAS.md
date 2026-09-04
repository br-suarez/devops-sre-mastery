# Notas — 01-linux-scripting

## Fecha de inicio
2026-08-11

## Resultado del diagnóstico

- [ ] Aprobado → ruta rápida (avanzado + capstone + break-fix)
- [*] No aprobado → módulo completo desde fundamentos

Qué falló y por qué:
Decidí hacer todos los laboratorios en su totalidad con el fin de estudiar, repasar y afianzar la disciplina de scripting robusto sin plantillas.

## Comandos que tuve que buscar

| Comando | Para qué | ¿Lo recordaba? |
|---------|----------|----------------|
| `strace -c -p <pid>` | Conteo de llamadas al sistema (syscalls) | No la opción `-c` |
| `cat /proc/<pid>/wchan` | Nombre de la función del kernel donde duerme el proceso | Sí, de `archive/` |
| `cat /proc/<pid>/status` | Ver estado (S/D/R), memoria y cambios de contexto | Sí |
| `lsof -p <pid>` | Listar descriptores de archivo, sockets y pipes abiertos | Sí |
| `timeout 5 strace ...` | Acotar el tiempo de ejecución de strace para evitar overhead | No recordaba usar `timeout` envuelto |

## Errores que cometí

| Síntoma | Qué pensé que era | Qué era en realidad | Comando que lo reveló |
|---------|-------------------|---------------------|-----------------------|
| `shellcheck` falló con advertencias SC2329 | Funciones `trap` no usadas | ShellCheck no asociaba funciones `trap` declaradas antes del `trap` | `shellcheck modules/01-linux-scripting/labs/deploy-check.sh` |
| Permiso denegado al ejecutar `verify.sh` | Fallo de sintaxis | Falta de permiso `chmod +x` | `/usr/bin/bash: Permiso denegado` |
| Duplicación de cabecera `#!/usr/bin/env bash` | Confusión de pegado en editor | Copy-paste accidental durante refactor de `deploy-check.sh` | `git diff` |

## Break-fix — Scripting Robusto & Failure Handling

**Laboratorio 01.01 (`deploy-check.sh`):**
- **Abordaje:** Implementado en Bash puro con `set -euo pipefail`. Se incluyeron timeouts estrictos (`--connect-timeout 3 --max-time 10`) en `curl`, reintentos con backoff exponencial (1s, 2s, 4s), captura de trampas `trap on_exit EXIT INT TERM` para limpieza garantizada de archivos temporales `$TMP_DIR`, y verificación dual de JSON (vía `jq` con fallback a `python3`).
- **Verificación:** Aprobado con `shellcheck` limpio y probado con el backend `pulse-api` vivo.

## Forense de Procesos — Resultados de Labs 01.02

| Escenario | Hipótesis | Comando que lo confirmó | Qué aprendí / Confirmación |
|---|---|---|---|
| **A: Spinner** (`while :; do :; done`) | CPU al 100% en espacio de usuario. | `strace -c -p <pid>` + `top` | `strace` vacío **ES** el diagnóstico: 0 llamadas al sistema. El tiempo se gasta 100% en espacio de usuario. |
| **B: Bloqueado** (`cat /tmp/fifo`) | Bloqueado esperando I/O en canal Named Pipe. | `cat /proc/<pid>/wchan` | Muestra `pipe_wait` / `pipe_read`. `wchan` responde en 1 ms sin sobrecarga. |
| **C: Syscall Storm** (`while :; do echo x > /dev/null; done`) | CPU al 100% debido a tempestades de llamadas al sistema `write`. | `timeout 5 strace -c -p <pid>` | Miles de `write` por segundo dominan el CPU. A diferencia de A, el cuello de botella es el cambio de contexto usuario-kernel. |

## Graceful Shutdown & PID 1 — Lab 01.04

- **Diferencia con/sin Graceful Shutdown:** Sin manejo de `SIGTERM`, las peticiones en vuelo se cortan con error `000 / Connection Refused`. Con `signal.Notify` en Go, la aplicación cierra el socket de escucha, procesa las peticiones pendientes y sale limpiamente (HTTP 200).
- **El Problema del PID 1 en Contenedores:** El kernel trata al PID 1 de forma especial y no le aplica las acciones por defecto de las señales. Si se usa la forma shell en Dockerfile (`CMD ./pulse-api`), `/bin/sh` corre como PID 1 y no reenvía `SIGTERM` al binario hijo, forzando a Docker a esperar 10 segundos antes de matar el contenedor con `SIGKILL`.
- **Forma Correcta en Dockerfile:** Usar siempre la forma exec `CMD ["./pulse-api"]` para que el proceso Go reciba directamente el `SIGTERM` como PID 1 y se apague de inmediato.

## Trade-offs: ¿puedo defender mi decisión?

**Decisión que tomé:** Obligar a que todo script de producción lleve `set -euo pipefail` y trampas de limpieza `trap` desde la primera línea.
- **Alternativa 1 descartada:** Confiar en `set -e` solo. Descartada porque `set -e` ignora fallos en condicionales `if`, estructuras `||` / `&&` y comandos intermedios de un pipeline sin `pipefail`.
- **Alternativa 2 descartada:** Validar con comprobaciones manuales `if [ $? -ne 0 ]` tras cada línea. Descartada por verbosidad extrema y propenso a omitir fallos no previstos.

## Autoevaluación (1-5)

| Criterio de salida | Nivel |
|--------------------|-------|
| Lo implemento sin documentación al lado | 4 |
| Depuro un fallo nuevo en esta tecnología | 4 |
| Explico trade-offs frente a 2 alternativas | 5 |
| Lo defiendo en entrevista senior | 4 |

## Pendiente / dudas para el repaso a 30 días
1. **Robustez en Bash:** `set -e` NO aborta si el comando está dentro de una condición `if` o `||`.
2. **Pipelines:** `set -o pipefail` es imprescindible para que el fallo en el primer elemento de un pipe no quede enmascarado por el `exit 0` de `grep`.
