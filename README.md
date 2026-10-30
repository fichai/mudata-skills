# Skills de Mudata

Skills (formato Agent Skills: `SKILL.md` con `name` y `description`) para que cualquier persona de la red Mudafy que conecte su IA al MCP de Mudata saque informes con el mismo criterio y el mismo diseño.

| Skill | Para qué |
|---|---|
| `mudata-reglas` | Cómo consultar Mudata sin equivocarse: flujo, tablas correctas y trampas |
| `mudafy-informes` | Estructura, formato de números, paleta y plantilla HTML de cualquier informe |
| `mudafy-analisis-adquisicion` | Análisis de adquisición de casos y leads por zona |

Cada persona ve solo su alcance: el servidor filtra por oficinas (un asesor ve solo lo suyo y algunas tablas son solo para regionales). Los skills no dan acceso a nada: hace falta tener conectado el MCP de Mudata.

## Instalar en Claude Code, Codex, Cursor y otros

```bash
npx -y skills add https://github.com/fichai/mudata-skills
```

El comando detecta los skills de la carpeta `skills/` y pregunta cuáles instalar y en qué agente. Para ver la lista sin instalar, agregá `--list`.

## Instalar en Claude web (claude.ai)

1. Entrá a la última [Release](https://github.com/fichai/mudata-skills/releases) y bajá los tres `.zip`.
2. En Claude: Configuración › Capacidades › Skills › subir skill, y subí cada `.zip`.
3. Conectá el MCP de Mudata desde Configuración › Conectores.

## Desarrollo

```bash
bash scripts/build-zips.sh   # arma dist/<skill>.zip, uno por skill
```

Para publicar una versión: `git tag v1.0.0 && git push --tags`. El workflow `release.yml` arma los zips y los sube a la Release.

Los skills no llevan datos internos ni nombres de personas. Si se agrega una tabla o regla nueva en Mudata, actualizá `mudata-reglas`.
