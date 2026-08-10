# PLAN — Calendario semana por semana

**Inicio:** martes 2026-08-11  (primera sesión)
**Objetivo:** martes 2027-03-02
**Ritmo:** 3 bloques de 120 min — **martes, miércoles y jueves, 19:00–21:00** = 6 h/semana

---

## Las dos rutas

Este plan tiene dos calendarios porque tiene dos públicos, y el diagnóstico de
cada módulo decide en cuál estás.

| Ruta | Bloques | Semanas | Fin |
|---|---|---|---|
| **A — con diagnósticos aprobados** (la esperada para ti) | 72 | 25 contenido + 5 reserva = 30 | **2027-03-02** |
| **B — módulo completo, sin saltar nada** (principiante) | 96 | 32 contenido + 5 reserva = 37 | 2027-04-22 |

La ruta A asume que apruebas el diagnóstico de los módulos 01, 03, 04, 11 y 13 —
razonable dado el trabajo de `archive/sre-track/`. **Si no lo apruebas, no pasa
nada: haces el módulo completo y te desplazas hacia la ruta B.** El calendario de
abajo es el de la ruta A; las 4 semanas de reserva son exactamente el colchón que
compran los diagnósticos.

### Reajuste de pesos (2026-08-02)

**Ronda 1 — cero bloques netos:**

| Cambio | Bloques | Motivo |
|---|---|---|
| Gateway API 6 → 5 | −1 | Ingress domina la base instalada; es inversión a 2–3 años, no a corto plazo. Los labs 06–08 pasan a opcionales |
| Jenkins & Ansible 4 → 3 | −1 | Leer un Jenkinsfile sabiendo Actions es traducción, no aprendizaje. Dentro del módulo, 1 bloque a Jenkins y 2 a Ansible, que no es legacy |
| **Game Day I** tras el módulo 08 | +2 | El módulo de mayor valor estaba solo al final, donde el protocolo de atraso lo sacrifica |

**Ronda 2 — +6 bloques, de 26 a 28 semanas:**

| Cambio | Bloques | Motivo |
|---|---|---|
| **Módulo 08b — eBPF y profiling continuo** | +4 | Responde la pregunta que la instrumentación no puede: qué haces cuando no puedes tocar el código. Va justo después del 08 para que el contraste sea agudo |
| Módulo 14 — unit economics y rightsizing | +1 | El coste es una restricción sobre decisiones de fiabilidad. Coste por 1.000 sondeos, derivado de datos que ya generaste. $0 |
| Módulo 16 — un experimento diseñado | +1 | Los Game Days son simulacros: entrenan reacción. Un experimento con hipótesis y estado estable declarado antes es otra disciplina, y es la que escala |

Descartado en esta ronda: **plataformas internas / IDP**. Montar un Backstage en
dos semanas produce algo superficial, y superficial es peor que ausente — invita
a decir en una entrevista que sabes algo que no sabes.

---

## Checkpoints — la red de seguridad del capstone

El capstone acumula, y eso es lo que lo hace valioso. También lo convierte en un
punto único de fallo: una plataforma a medio migrar en el módulo 09 puede
bloquear el 10 por razones que no tienen nada que ver con aprender el 10.

**La regla: al cerrar cada módulo, etiquetas el estado bueno conocido.**

```bash
./scripts/checkpoint.sh save 05
```

Si un módulo posterior se atasca por deuda de plataforma y no por el material:

```bash
./scripts/checkpoint.sh list
./scripts/checkpoint.sh diff 05        # qué cambió desde entonces
./scripts/checkpoint.sh restore 05     # rama nueva desde ese estado
./scripts/checkpoint.sh rebuild 05     # cluster desde cero hasta ahí
```

`restore` crea una **rama**, nunca descarta tu trabajo posterior: recuperarte de
un estado malo no puede costarte lo que te llevó hasta él.

Esto **no** permite saltarse un módulo — la etiqueta solo existe si lo cerraste
bien. Lo único que hace es impedir que un problema de entorno se convierta en un
problema de currículo.

No optimices para llegar el 17 de febrero. Optimiza para que los criterios de
salida se cumplan de verdad. La fecha es maleable; el criterio no.

---

## Calendario

Leyenda de bloques: `05×3` = tres bloques del módulo 05 esa semana.

| Sem | Lunes | Bloques | Hito |
|---|---|---|---|
| 1 | 2026-08-10 | `00×2` `01×1` | Entorno reproducible |
| 2 | 2026-08-17 | `01×1` `02×2` | Harness `verify.sh` terminado |
| 3 | 2026-08-24 | `02×2` `03×1` | **Pulse tras NGINX con TLS** |
| 4 | 2026-08-31 | `03×1` `04×2` | **Compose, distroless, Pulse en kind** |
| 5 | 2026-09-07 | `05×3` | **NGINX sustituido por Gateway API** |
| 6 | 2026-09-14 | `05×2` `06×1` | **NGINX sustituido por Gateway API** |
| 7 | 2026-09-21 | `06×3` | **Postgres con estado, drill de backup** |
| 8 | 2026-09-28 | — | 🟡 **RESERVA** + repaso espaciado |
| 9 | 2026-10-05 | `06×1` `07×2` | **Postgres con estado, drill de backup** |
| 10 | 2026-10-12 | `07×2` `08×1` | **SLO y recording rule 8s → <1s** |
| 11 | 2026-10-19 | `08×3` | **Trazas propias, exemplars** |
| 12 | 2026-10-26 | `08×2` `08b×1` | **Trazas propias, exemplars** |
| 13 | 2026-11-02 | `08b×3` | **Flamegraph de un pod vivo** |
| 14 | 2026-11-09 | — | 🟡 **RESERVA** + repaso espaciado |
| 15 | 2026-11-16 | `08c×2` `09×1` | 🔥 **Game Day I + postmortem** |
| 16 | 2026-11-23 | `09×3` | **Pipeline verde con SBOM** |
| 17 | 2026-11-30 | `10×3` | **Argo CD gobierna el cluster** |
| 18 | 2026-12-07 | `10×2` + consolidación | **Argo CD gobierna el cluster** + checkpoint pre-parón |
| 19 | 2026-12-14 | — | 🎄 **RESERVA** — Navidad |
| 20 | 2026-12-21 | — | 🎄 **RESERVA** — Navidad |
| 21 | 2026-12-28 | — | 🎄 **RESERVA** — Navidad |
| 22 | 2027-01-04 | `11×2` `12×1` | **Canary con rollback por SLO** |
| 23 | 2027-01-11 | `12×3` | **Solo imágenes firmadas** |
| 24 | 2027-01-18 | `12×1` `13×2` | Infra como módulos Terraform |
| 25 | 2027-01-25 | `13×1` `14×2` | **Pulse en GKE, y destruido** |
| 26 | 2027-02-01 | `14×3` | **Pulse en GKE, y destruido** |
| 27 | 2027-02-08 | `14×2` `15×1` | **Pulse en GKE, y destruido** |
| 28 | 2027-02-15 | `15×2` `16×1` | Comparativa Jenkins vs Actions |
| 29 | 2027-02-22 | `16×3` | 🏁 **Game Day II + arquitectura** |
| 30 | 2027-03-01 | `16×1` | 🏁 **Game Day II + arquitectura** |

Las semanas 19, 20 y 21 son reserva por calendario, no por diseño. Si llegas
adelantado, adelanta el módulo 14 — es el único con costo y conviene ejecutarlo
concentrado.

**Sobre el arranque en martes (reprogramado 2026-08-09).** El calendario anterior
empezaba un jueves, así que su semana 1 tenía un solo bloque de los tres
disponibles. Arrancar en martes recupera esos dos bloques y el track pasa de 29
semanas a 28 sin comprimir contenido: los 72 bloques de la ruta A son ahora 24
semanas de 3 bloques más las 4 de reserva, exacto. La fecha objetivo se mueve un
día, del miércoles 17 al jueves 18 de febrero.

**Sobre el Game Day I (semana 15, martes 17 y miércoles 18 de noviembre):** los
tres labs suman 120 minutos exactos —repaso 20 + ronda 60 + postmortem 40— así
que **todo el ejercicio cabe en la sesión del martes**, incluido el postmortem.
El bloque del miércoles es para la remediación: implementar la comprobación que
faltaba en `verify.sh` y verificar que caza el fallo.

Lo que no se puede partir es el incidente y su postmortem. Escrito cinco días
después es ficción — te acuerdas de la versión ordenada, no de los callejones sin
salida, que son la parte útil. Con el arranque en martes los dos bloques caen en
días consecutivos de la misma semana, que es la mejor colocación posible: antes
estaban separados por un fin de semana y un cambio de semana.

**Sobre el parón de Navidad (revisado 2026-08-09).** Son **tres** semanas de
reserva seguidas —14, 21 y 28 de diciembre—, no dos. La semana del 14 se declaró
reserva porque no es tiempo de estudio real, y declararlo por adelantado es mejor
que arrastrar el atraso en enero fingiendo que sí lo era.

La consecuencia es que **ningún módulo cruza el hueco**: el 10 cierra el 9 de
diciembre y el 11 arranca entero el 5 de enero. Eso importa más de lo que parece
— el módulo 11 son dos bloques que montan un canary con análisis contra el SLO
del módulo 07, y partirlo por un parón de tres semanas significaría volver en
enero a un `Rollout` a medio configurar sin acordarte de por qué.

El precio son **dos semanas de calendario**: una es la reserva nueva, y la otra
sale de que los 47 bloques hasta el módulo 10 no llenan las 16 semanas de
contenido previas al parón. Sobra exactamente un bloque, y ese es el de
consolidación de la semana 18.

**El bloque de consolidación (jueves 10 de diciembre)** no es relleno. Vas a
dejar la plataforma sola tres semanas, así que ese bloque es: `checkpoint.sh save
10`, levantar Pulse desde cero contra el checkpoint para comprobar que el estado
bueno conocido lo es de verdad, y repasar la capa de observabilidad (07–08b) que
para entonces llevará seis semanas sin tocarse. Volver en enero a una plataforma
que no arranca es la forma más rápida de perder también la primera semana de
enero.

**Sobre el Game Day I:** es el cambio de diseño más importante del plan. El
módulo de mayor valor —depurar algo que no habías visto, bajo presión— estaba
solo al final, en la posición exacta que el protocolo de atraso sacrifica. Ahora
hay uno a mitad de camino, contra un sistema de siete capas en vez de trece, y
los dos postmortems separados por trece semanas son la medida más honesta de
progreso de todo el repo.

**Sobre el módulo 08b (eBPF):** ahora cae entero y seguido en las semanas 12 y
13, y la reserva de la semana 14 queda justo entre él y el Game Day I. Esa es
mejor posición que la anterior: llegas al incidente con el profiling reciente y
una semana de colchón por si el módulo se alargó.

---

## Repaso espaciado

Dos mecanismos, y ninguno es opcional. El olvido no es una hipótesis.

### 1. Dentro de cada módulo (7 días)

Todo módulo abre con **2–3 ejercicios cortos** (15 min en total) de módulos
anteriores, en `labs/00-repaso.md`. Se hacen **antes** del diagnóstico, en frío y
sin consultar notas. Es deliberado: si no te sale, acabas de encontrar el tema
para el repaso a 30 días.

### 2. Sesiones programadas (30 y 90 días)

Ocupan las semanas de reserva. Fuente: las columnas "comandos que tuve que
buscar" y "errores que cometí" de cada `NOTAS.md`, más `PREGUNTAS.md`.

| Cuándo | Semana | Fecha | Repasa | Formato |
|---|---|---|---|---|
| 30 d | 8 | 2026-09-28 | módulos 00–02 | Rehacer el break-fix de memoria, cronometrado |
| 30 d | 14 | 2026-11-09 | módulos 05–07 | Ídem + preguntas de entrevista en voz alta |
| 90 d | 14 | 2026-11-09 | módulos 00–02 | Levantar Pulse desde cero sin mirar el README |
| 45 d | 18 | 2026-12-10 | módulos 07–08b | Bloque de consolidación pre-parón (ver arriba) |
| 30 d | 20 | 2026-12-21 | módulos 08b–10 | Break-fix + explicar trade-offs |
| 90 d | 21 | 2026-12-28 | módulos 05–08 | Reconstruir la capa de observabilidad de cero |
| 90 d | 29 | 2027-02-22 | módulos 09–14 | Integrado en el Game Day II |

Las cuatro primeras filas caen ahora **dentro** de una semana de reserva, que es
donde el plan dice que van. En la versión anterior las dos primeras apuntaban a
semanas de contenido (7 y 13) mientras la reserva estaba en la 8 y la 14, y esa
sesión de repaso no tenía hueco real donde ocurrir.

El repaso de 30 días de la semana 20 cubre **08b–10**: los módulos 11 y 12 no
arrancan hasta enero, y no se repasa lo que aún no has hecho.

**La regla del repaso:** si tienes que abrir el README de un módulo que ya
cerraste, ese módulo no estaba cerrado. Marca su nivel a la baja en `TRACKER.md`
y programa una sesión extra. Bajar una nota propia es información, no fracaso.

---

## Niveles de contenido

Todo el contenido de cada módulo está etiquetado. Esto es lo que hace posible el
protocolo de atraso.

| Nivel | Qué es | ¿Se puede saltar? |
|---|---|---|
| **CORE** | Define el criterio de salida del módulo | **Nunca** |
| **EXTEND** | Profundidad adicional, casos borde | Sí, si hay atraso |
| **DEEP** | Exploración opcional | Sí, libremente |

---

## Protocolo de atraso

Un plan sin esto muere en el primer mes malo. Estas reglas se aplican solas: no
son una sugerencia para cuando tengas ganas de decidir.

### Vas 1 semana por detrás

No hagas nada. Para eso están las 4 semanas de reserva. Sigue el calendario.

### Vas 2 semanas por detrás

1. Elimina **todo el contenido EXTEND** del módulo actual y del siguiente.
2. Consume una semana de reserva.
3. **No elimines el break-fix.** Es el ejercicio con mayor retorno por minuto de
   todo el módulo, y es exactamente lo que se evalúa en entrevista.

### Vas 4 semanas por detrás

Modo compresión. En este orden:

1. Elimina EXTEND y DEEP de todos los módulos restantes.
2. Fusiona **15 en 16**: el Jenkinsfile se escribe como parte del Game Day y la
   comparativa se convierte en una sección del postmortem.
3. Convierte el módulo **14 en `plan`-only**: se valida el Terraform contra GCP
   con `terraform plan` y `gcloud ... --dry-run`, sin `apply`. Se documenta que
   no se ejecutó, igual que hiciste en el módulo 23 de `archive/`.
4. Mueve la fecha objetivo. **Mover la fecha es una decisión válida; fingir que
   completaste un módulo no lo es.**

### Vas más de 6 semanas por detrás

Para y replantea. Probablemente el problema no es el plan sino que 6 h/semana
dejaron de ser realistas. Reduce a 4 h/semana y recalcula, en vez de acumular
deuda y abandonar.

### Lo que no se salta nunca, en ningún escenario

- El **break-fix** de cada módulo.
- La **capa del capstone** — si te la saltas, el módulo siguiente no arranca.
- El **README de portafolio** — es el entregable, y escribirlo es la mitad del
  aprendizaje.

---

## Cómo es un bloque de 120 minutos

No es una sesión de lectura. Estructura sugerida:

| Min | Qué |
|---|---|
| 0–15 | Repaso corto del módulo anterior (`labs/00-repaso.md`), en frío |
| 15–95 | Trabajo del lab. Sin documentación abierta en el primer intento |
| 95–110 | La capa del capstone: dejar la plataforma desplegable |
| 110–120 | Rellenar `NOTAS.md` **mientras está fresco**, no después |

Los últimos 10 minutos son los que más se saltan y los que más valen. La columna
"errores que cometí" es la materia prima del repaso y de las respuestas de
entrevista.

### Regla del primer intento

En todo lab, el primer intento va **sin documentación**. Cuando te atasques,
anota qué buscaste antes de buscarlo. Esa lista es el mapa exacto de lo que aún
no dominas — y es lo que separa el criterio de salida "lo sé hacer" del criterio
"lo sé hacer sin ayuda".

---

## Estado de bloqueo

Si un lab te tiene bloqueado más de **45 minutos sin progreso medible**:

1. Escribe en `NOTAS.md` qué esperabas y qué observas. Con frecuencia esto lo
   resuelve solo.
2. Usa la siguiente pista escalonada del lab.
3. Si sigues bloqueado, **sáltalo y continúa**, marcándolo en `TRACKER.md`.
   Vuelve en la semana de reserva.

Atascarse tres horas en un problema de entorno no es perseverancia; es la forma
más común de abandonar un plan de estudios.
