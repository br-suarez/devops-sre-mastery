# Notas — 01-linux-scripting

> Plantilla vacía. Estas notas son para ti, en español. El README del módulo
> (formato portafolio) va en inglés.

## Fecha de inicio

## Resultado del diagnóstico

- [ ] Aprobado → ruta rápida (avanzado + capstone + break-fix)
- [*] No aprobado → módulo completo desde fundamentos

Qué falló y por qué:
Decidí hacer todos los laboratorios en su totalidad con el fin de estudiar y repasar

## Comandos que tuve que buscar

> Todo lo que anotes aquí es material directo para el repaso a 7 días.

| Comando | Para qué | ¿Lo recordaba? |
|---------|----------|----------------|
|         |          |                |

## Errores que cometí

> El más valioso del módulo. Un error propio bien entendido vale más que tres labs.

| Síntoma | Qué pensé que era | Qué era en realidad | Comando que lo reveló |
|---------|-------------------|---------------------|-----------------------|
|         |                   |                     |                       |

## Break-fix

Tiempo hasta el diagnóstico:
Tiempo hasta la solución:
Pistas usadas (0-3):

Cómo lo abordé:


## Trade-offs: ¿puedo defender mi decisión?

Decisión que tomé:
Alternativa 1 descartada y por qué:
Alternativa 2 descartada y por qué:
Cuándo elegiría otra cosa:


## Autoevaluación (1-5)

| Criterio de salida | Nivel |
|--------------------|-------|
| Lo implemento sin documentación al lado | |
| Depuro un fallo nuevo en esta tecnología | |
| Explico trade-offs frente a 2 alternativas | |
| Lo defiendo en entrevista senior | |

## Pendiente / dudas para el repaso a 30 días
1. Robustez en Bash: ¿Por qué set -e por sí solo NO es suficiente para garantizar que un script de Bash se detenga ante cualquier error? Decime al menos un caso donde set -e falla en silencio.
    Dentro de un if/||/&&: if comando_que_falla; then ... → set -e NO aborta porque el comando está dentro de una condición.
    En un pipeline sin pipefail: comando_que_falla | grep algo → solo se evalúa el exit code del último comando del pipe (grep). Si grep encuentra algo y sale con 0, el fallo del primer comando se pierde. Por eso se necesita set -o pipefail.