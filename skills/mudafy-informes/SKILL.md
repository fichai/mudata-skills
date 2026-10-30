---
name: mudafy-informes
description: Diseño y forma estándar de cualquier informe, tabla, gráfico, resumen o página hecha con datos de Mudata, para que todos los de la red Mudafy salgan iguales. Se usa cuando pidan "armá un informe", "un reporte", "un resumen", "un gráfico", "una página" o "un dashboard" con datos de Mudafy. Define estructura, formato de números en español, paleta de marca, reglas de gráficos, tono y una plantilla HTML con modo claro y oscuro.
---

# Informes de Mudafy

Consultá los datos con el skill `mudata-reglas`; este skill define cómo se presentan.

## Estructura

1. **Título** claro, con la conclusión principal si hay una.
2. **Una línea de contexto**: período y alcance (qué oficinas o qué red), por ejemplo "Enero a septiembre de 2026 · Oficinas de Córdoba".
3. **3 o 4 KPIs** arriba: cifra grande, etiqueta corta y, si hay, variación contra el período comparable.
4. **Secciones** cuyo título es la conclusión, no el tema: "La captación cayó 18 % en septiembre", no "Captación". Cada una con una o dos frases de lectura y una tabla corta o un gráfico.
5. **Notas** de datos parciales o limitaciones (qué mes es parcial, qué no se pudo ver por permisos).
6. **Pie**: "Fuente: Mudata · datos al <fecha>".

Tablas de hasta ~10 filas; el resto, en "Otras" o aparte. Ordená por lo que importa, no alfabético.

## Números en español

- Miles con punto, decimales con coma: `12.345`, `3,5`.
- Dólares: `US$ 12.345`. Millones: `US$ 1,2 M`. No mezcles monedas; todo en USD salvo pedido expreso.
- Porcentajes con a lo sumo una cifra decimal: `18 %` o `18,4 %` (espacio antes del %).
- Redondeá lo que se lee a ojo: sin decimales en montos grandes y conteos.
- El mes en curso y el anterior se marcan "(parcial)" en tablas y gráficos; no los compares como si estuvieran completos. Si proyectás el mes en curso, decilo y mostrá la fórmula.
- Fechas: `15 de octubre de 2026` en texto, `oct-2026` o `oct 26` en ejes.

## Paleta de marca

| Uso | Color |
|---|---|
| Primario (títulos, KPIs, barras principales) | `#283777` |
| Navy profundo (texto fuerte, fondos oscuros) | `#021d49` / `#082f54` |
| Acento | `#6679d6` |
| Acento claro | `#7e96f5` |
| Coral: solo algo negativo o una alerta | `#ff5566` |
| Resto / otros | grises |

Series categóricas, en este orden: `#283777`, `#6679d6`, `#009689`, `#f54900`, `#8b5cf6`, `#e11d78`. "Resto" y "Otros" siempre en gris.

**Contraste**: sobre blanco, `#283777` (11:1) y `#021d49` (16:1) sirven para texto. Los demás (`#6679d6` 4,0:1, `#009689` 3,7:1, `#f54900` 3,6:1, `#7e96f5` 2,8:1, `#ff5566` 3,1:1) son solo para marcas (barras, líneas, puntos), nunca para texto chico. En modo oscuro el texto va en un tono claro (`#c9d2fb`), no en el primario. Nunca transmitas algo solo con el color: sumá etiqueta, signo o posición.

Tipografía: sans del sistema (`Inter` si está disponible).

## Gráficos

- Barras para comparar categorías, líneas para tendencias mensuales.
- Barras con eje desde cero. Líneas pueden recortar el eje solo si se aclara.
- Sin tortas con más de 4 porciones (preferí barras). Nada de 3D ni sombras.
- Etiquetas directas sobre barras y finales de línea en vez de leyenda cuando se pueda.
- Un mensaje por gráfico, con título que lo diga. Como mucho 6 series.
- Meses parciales: barra con trama o más clara, o línea punteada, y la leyenda "(parcial)".

## Tono

- Español neutro. Si la persona escribe con voseo (Argentina), respondé con voseo; si no, tuteo.
- Directo, con la cifra y su lectura. Sin jerga de tablas: nada de `fct_offers`, `is_signed` ni nombres de columnas en el informe; hablá de "operaciones firmadas", "GCI", "casos".
- Decí qué es parcial, qué quedó afuera por permisos y qué es estimación.

## Si el asistente puede crear artefactos o HTML

Partí de `references/plantilla.html`: variables CSS con la paleta, modo claro y oscuro, encabezado de texto "Mudafy" (sin logos), KPIs, tabla y gráfico de barras en SVG. Reemplazá los datos de ejemplo por los reales y respetá las secciones. Si no puede crear archivos, entregá el mismo orden en texto con tablas Markdown.
