# Notas — 00-bootstrap

> El README del módulo (formato portafolio) va en inglés.

## Fecha de inicio
07/08/2026

## Resultado del diagnóstico

- [ ] Aprobado → ruta rápida (avanzado + capstone + break-fix)
- [*] No aprobado → módulo completo desde fundamentos

Qué falló y por qué:
Varios conceptos que no recordaba

## Comandos que tuve que buscar
**Case**: no es un comando en sí, pero no recordaba la sintáxis
**basename**: para tomar la última palabra de una ruta

## Errores que cometí
- install_shell_helpers comprueba y escribe en ~/.bashrc. Yo uso zsh. 
- Verificado ahora mismo: cero líneas en .bashrc, cero en .zshrc.
- Accidente de pegado: al meter el case se perdieron dos bloques.
- Casos:
    - Return suelto en bootstrap.sh, detectado mirándolo
    - [[ sin espacios, detectado por shellcheck
    - check() devuelve 1 sin VERBOSE, detectado por bash -x
- shellcheck me avisó de que A && B || C es traicionero, y al reescribirlo introduje un bug peor que el original, **linters** me dicen qué es sospechoso, no si mi caso concreto lo es. Un aviso info que reescribo sin entender puede ser peligroso
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

## lab 01
### Respuestas 
1. El curl -o guarda en un archivo en lugar de la salida estándar, fetch_binary lo descarga en tmp y muere si la descarga falla le da cambia los permisos y crea un folder nuevo
2. kind version -q da una salida de solo numeros, ocupamos el formato v####,  
3. Lo que no le pertenece a mi usuario o hace cambios en archivos de otros requiere sudo
4. Porque el comando requiere que me desloguee y loguee de nuevo, una nueva sesión para cargar los nuevos settings
5. Sólo excluye Docker que es el único actualizado, instala kind v0.32.0, kubectl 1.36, heml 4.2, terraform 1.15, trivy 0.72, cosign 3.1 

## lab 02
Antes:
```bash
Mem:           7.7Gi       674Mi       6.8Gi       3.5Mi       502Mi       7.1Gi
Swap:          2.0Gi          0B       2.0Gi
```
Después:
```bash
Mem:            11Gi       664Mi        10Gi       3.4Mi       490Mi        11Gi
Swap:          8.0Gi          0B       8.0Gi
```
Perfil: ha — 3 cp + 2 workers

## lab 03
1. How many containers did kind create, and what is each one?
    2
2. Where did your kubeconfig go? What context name did it add?
    kind-pulse-lite
3. kubectl get nodes -o wide — what container runtime is reported, and what Kubernetes version? Does the version match the one pinned in SETUP.md?
    Sí. es la v1.36.1
4. kubectl get pods -A — name every pod running and say in one line what each is for. This is the control plane; you should be able to account for all of it.
    - coredns: Servicio de DNS para enrutar pods
    - etcd-pulse-lite-control-plane: Base de datos etcd
    - kindnet: Agente Kind? No esoy muy seguro
    - kube-apiserver: Servidor API 
    - kube-controller-manager-pulse-lite-control-plane: Control Plane
    - kube-proxy: Servidor Proxy
    - kube-scheduler: Encargado de asignar recursos y resplegar tareas/pods
    - local-path-provisioner: Servidor Storage