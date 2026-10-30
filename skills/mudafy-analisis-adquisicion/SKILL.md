---
name: mudafy-analisis-adquisicion
description: Análisis de la adquisición de casos y consultas de Mudafy en una zona (provincia, ciudad o barrio, AR o MX) con datos de Mudata - volumen y tendencia, origen (portales, Meta, mudafy.com, prospección), stock propio vs alianzas, por oficina y barrio, demanda vs stock y calidad de cada origen. Se usa cuando pidan "analizá la adquisición en X", "cómo venimos con los leads o casos en X", "de dónde vienen los casos", "cuántos son de alianzas", "dónde no estamos generando" o comparar zonas u oficinas.
---

# Análisis de adquisición por zona

Responde en una pasada: **cuánto generamos, de dónde, con qué stock, dónde no llegamos y qué convierte**. Todo sale de Mudata (herramientas `list_scopes`, `describe_data`, `query_facts`). Las reglas generales de consulta están en el skill `mudata-reglas`; el informe final sigue el skill `mudafy-informes`.

## Alcance de cada persona

Cada persona ve solo su alcance: el servidor filtra por oficinas, y un asesor ve solo lo suyo. Algunas tablas (tráfico y leads del sitio mudafy.com, Search Console, GA4, presupuesto de marketing) las ven solo super admins y regionales. Si una query no devuelve nada o falla por permisos, decilo en el informe ("esta parte no está disponible con tu acceso") y seguí con el resto. Llamá `list_scopes` al empezar para saber qué se puede cubrir.

## 0. Parámetros

- **Zona** y su nivel: `location_provincia` / `location_ciudad` / `location_barrio` (nombre exacto con tilde, ej. `Córdoba`; si dudás, primero un `contains` agrupando por la columna).
- **Ventana**: por defecto 12 meses cerrados + mes en curso para la tendencia, y los últimos ~6 meses para los cortes. El mes en curso y el anterior son **parciales**: proyectá el mes en curso (casos / días transcurridos × días del mes) y decilo.
- **País**: AR = mudafy.com.ar, MX = .com.mx (para las tablas de marketplace).

No hace falta `describe_data` si las columnas de abajo no cambiaron; si una query falla por columna, describí esa tabla.

## 1. Queries (correrlas en paralelo, en dos tandas)

**Tanda 1 - casos (`fct_cases`, filtro de zona, `date_range` sobre `created_date`)**

1. Mes × `stock_type` (own / alliance / intermediary / none) → volumen y % alianzas.
2. Mes × `origin_group` → mix de origen y tendencia por canal.
3. Mes × `case_type` × `operation` → compra / alquiler (leasing) / captación (selling, renting).
4. `office_name` × `stock_type` (últimos 6 m) → concentración por oficina. `office_name` NULL = leads de mudafy.com sin oficina (alianzas/intermediación del marketplace).
5. `location_ciudad` (o `location_barrio` si la zona es una ciudad) × `stock_type` → dónde generamos.
6. `origin_group` × `stock_type` × `case_type` (6 m) → qué canal trae casos de alianza.

Sin filtro de red se cuentan juntos los de la red y los sin oficina (= "como la pantalla"). Comprobalo con un group by `is_mudafy_network` (true + null = total; false no debería existir).

**Tanda 2 - oferta, demanda, upper funnel y calidad**

7. `fct_publications` con `is_listed=true`, zona → `tipo_de_venta` × `operation` (stock propio vs "Otras Inmobiliarias" = stock aliado del MLS disponible).
8. `fct_publications` listado por `location_barrio` × `tipo_de_venta` (top 60).
9. `fct_publications` de la red (`is_mudafy_network=true`) por `office_name` × ciudad.
10. `rep__zone_search_demand`: `site_id`, `zone_level='barrio'` (o `ciudad`), `window_days=90`, `dimension='ambientes'`, `rooms_bucket='all'`, `property_kind='all'`, `zone_slug contains <slug de la zona>`; métricas `max(cell_n_searches)`, `max(cell_n_visitors)` por `zone_name` × `operation`. Son tamaños de muestra internos: sirven para rankear zonas, no para publicar cifras absolutas.
11. `fct_marketplace_seo_pages_daily`: `country`, `path contains <slug>`, `is_final=true`; por mes × `section` (sum clicks, impressions, position_x_impressions) y top 25 paths del último mes por impresiones. Posición = pxi / impr.
12. `fct_marketplace_leads`: `country`, `landing_path contains <slug>`, mes × `channel` × `landing_section`.
13. `fct_offers`: zona, `is_signed=true`, `is_mudafy_network=true`, 12 m sobre `signed_date`; por `origin_group` × `in_network` × `operation`, `count` y `sum(signed_commission_usd)`.
14. Referencia país: `fct_cases` por trimestre × `stock_type` con `location_pais` = el país → % alianzas del país y peso de la zona.

**Modo "solo mudafy.com"** (cuando piden foco en el portal propio). Agregar a lo de arriba filtrando `origin_group='mudafy_com'`:

15. `fct_cases` semana × `stock_type` (zona) y mes × `stock_type` (país) → ver si un cambio es de la zona o de todo el sitio.
16. `fct_cases` país, `stock_type in (alliance, intermediary)`, semana × `is_mudafy_network` × `case_type` → los leads **sin oficina** (`is_mudafy_network` NULL: alquileres de alianza e intermediación) se ven acá.
17. `fct_marketplace_leads` país, semana × `lead_type` → si los leads siguen llegando y los casos no, el problema es de ruteo/creación de casos, no de tráfico.
18. `fct_ga4_daily_landing` `landing_page contains <slug>`: semana × `channel` (sesiones y engaged) y top landings con `key_events` (leads válidos desde 08-oct) → tasa de conversión por página.
19. `rep__mkt_budget_daily` `channel='google_ads'` por `campaign_name` (y semana para la campaña de la zona): inversión, consultas, casos, calificados → CPL y costo por calificado, comparado con las otras campañas.
20. `fct_cases` mes × `case_origin`: `portal` / `portal_whatsapp` / `portal_phone` da la forma de contacto.

## 2. Trampas (aprendidas)

- **Desde la semana del 14-sep-2026 no se crean casos sin oficina** (alquileres sobre stock aliado e intermediación) en todo AR, aunque los leads de alquiler siguen llegando. Si sigue así, comparar alianzas contra antes de esa fecha exagera la caída: separá `is_mudafy_network` true vs NULL y aclaralo en el informe.
- `rep__mkt_budget_daily` tiene inversión de Google Ads desde sep-2026; `fct_ga4_daily_ads` solo desde ~09-oct. Las consultas por campaña saltan desde el 15-oct (se une la visita web).
- `fct_ga4_daily_landing` es un top 500 por día: subestima la cola larga (fichas).
- **Origen = `origin_group`**, nunca `contact_source`. `prospectados` = captación propia del asesor (sobre todo casos `selling`).
- **Los portales solo traen stock propio**: los casos de alianza salen casi todos de `mudafy_com` (es el único lugar donde se publica stock aliado). El % de alianzas de una zona depende del tráfico de mudafy.com ahí, no de los portales.
- `fct_marketplace_leads` existe desde jul-2026 con canal recién desde 08-sep (Google Ads) y `organico` desde 02-oct. Filtrar por `landing_path` deja afuera las landings de ficha (su path no lleva la zona): es un **piso**. Leads ≠ casos (dedupe, multi-consulta).
- `fct_publication_performance` (vistas/leads por portal) no tiene zona ni oficina y no se puede cruzar desde `query_facts`: el embudo por portal de una zona no está disponible. Decilo.
- `fct_offers.origin_group` es el del caso comprador; las operaciones de `prospectados` incluyen las de punta vendedora. Ops / 1.000 casos por origen es un **ratio orientativo** (casos y firmas de cohortes distintas), no una tasa de conversión.
- Las tablas de búsqueda arrancan el 17-jul-2026 y tienen un hueco del 5 al 18-ago.
- No sumar montos sin `_usd`.

## 3. Cómo leerlo (el análisis, no solo las tablas)

1. **Volumen y tendencia**: casos/mes, récord, ritmo del mes en curso, peso en el país.
2. **Concentración**: % de la oficina principal; riesgo si una sola oficina es > 70 %.
3. **Mix de origen**: share por canal en la ventana y qué canal se movió (caídas/subidas > 30 % mes a mes, con la explicación posible: pauta de Meta, destaques, SEO).
4. **Alianzas**: % de casos con stock aliado vs el país, y **stock aliado / stock propio** listado. Si el aliado es varias veces el propio pero trae pocos casos, el cuello es la exposición en mudafy.com.
5. **Dónde generamos y dónde no**: cruzar por barrio/ciudad demanda (búsquedas) × stock propio × casos. Marcar: (a) alta demanda + poco stock propio + mucho aliado → oportunidad de alianzas/captación; (b) ciudades de la provincia con casi cero casos (interior) → zona sin cobertura; (c) alquiler: casos de leasing vs avisos propios en alquiler.
6. **Upper funnel mudafy.com**: clics orgánicos a páginas de la zona y su posición, páginas con muchas impresiones y posición > 8 (oportunidad SEO), leads por canal (Google Ads vs orgánico).
7. **Calidad**: ops y GCI por origen; ops/1.000 casos; qué canal trae volumen que no convierte.
8. **Recomendaciones**: 3-5, concretas, con el dato que las justifica.

## 4. Entrega

Informe siguiendo `mudafy-informes` (conclusiones como títulos, tablas cortas, cifras redondeadas, parciales marcados, fuente al pie). Aclarar qué partes no se pudieron ver por permisos.

Al final del informe, anotá la **línea de base** (zona, fecha, casos/mes, % alianzas, mix de origen) para poder compararla la próxima vez que alguien repita el análisis; no hay archivo persistente, así que que quede en el propio informe.
