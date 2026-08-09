# Notas — 00-bootstrap

> Plantilla vacía. Estas notas son para ti, en español. El README del módulo
> (formato portafolio) va en inglés.

## Fecha de inicio
07/08/2026

## Resultado del diagnóstico

- [ ] Aprobado → ruta rápida (avanzado + capstone + break-fix)
- [*] No aprobado → módulo completo desde fundamentos

Qué falló y por qué:


## Comandos que tuve que buscar


| Comando | Para qué | ¿Lo recordaba? |
|---------|----------|----------------|
|         |          |                |

## Errores que cometí
install_shell_helpers comprueba y escribe en ~/.bashrc. Tú usas zsh. Verificado ahora mismo: cero líneas en .bashrc, cero en .zshrc.
Accidente de pegado: al meterlo se perdieron dos bloques.

Lo que falta
Mira el orden actual:

  esac
    log "${DIM}would append kubectl completion to $rc${RESET}"    ← sin if
    return                                                        ← sin if

  {
    echo ''
Esas dos líneas quedaron sueltas, fuera de cualquier condicional. Antes estaban dentro de un if [ -n "$DRY_RUN" ].

Consecuencia: la función siempre imprime "would append" y siempre hace return. El bloque de escritura nunca se ejecuta. La función no hace nada, nunca, ni con --dry-run ni sin él.

Y también desapareció la comprobación de idempotencia — el grep que decía already current.

Lo que hay que restaurar
Van entre el esac y el bloque de escritura, en este orden:

  esac

  if grep -q 'devops-sre-mastery bootstrap' "$rc" 2>/dev/null; then
    present "kubectl completion and alias"
    return
  fi

  if [ -n "$DRY_RUN" ]; then
    log "${DIM}would append kubectl completion to $rc${RESET}"
    return
  fi

  {
    echo ''

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


## Respuestas 
1. El curl -o guarda en un archivo en lugar de la salida estándar, fetch_binary lo descarga en tmp y muere si la descarga falla le da cambia los permisos y crea un folder nuevo
2. kind version -q da una salida de solo numeros, ocupamos el formato v####,  
3. Lo que no le pertenece a mi usuario o hace cambios en archivos de otros requiere sudo
4. Porque el comando requiere que me desloguee y loguee de nuevo, una nueva sesión para cargar los nuevos settings
5. Sólo excluye Docker que es el único actualizado, instala kind v0.32.0, kubectl 1.36, heml 4.2, terraform 1.15, trivy 0.72, cosign 3.1 
