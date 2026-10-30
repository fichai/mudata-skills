---
name: mudata-reglas
description: Reglas para consultar Mudata (el MCP de datos de Mudafy) sin equivocarse. Se usa siempre que alguien pida un número, ranking o informe de Mudafy - "cuántas operaciones", "cuánto GCI", "cuántos casos o leads", "ranking de asesores u oficinas", "inventario", "captaciones", "mercado de una zona" - o cuando vaya a llamar list_scopes, describe_data o query_facts. Define el flujo de consulta, qué tabla usar para cada pregunta y las trampas que cambian el resultado.
---

# Cómo consultar Mudata

Mudata expone tres herramientas: `list_scopes`, `describe_data` y `query_facts`. Los datos se actualizan 3 veces por día. El servidor agrega solo el filtro por las oficinas de la persona (y por su usuario si es asesor): no hace falta pedirlo y no se puede sacar.

## Flujo

1. `list_scopes` si no sabés qué puede ver la persona (toda la base, una lista de oficinas con su id, o solo lo propio si es asesor). Los ids sirven para `office_ids` en `query_facts`.
2. `describe_data` antes de consultar una tabla por primera vez: trae columnas, valores posibles y trampas. Sin argumentos lista las tablas; con `domain`, las de ese dominio; con `table`, el detalle.
3. `query_facts`: métricas (`count`, `count_distinct`, `sum`, `avg`, `min`, `max`), agrupaciones (con `grain` para fechas), filtros y `date_range`. Devuelve hasta 1000 filas y el SQL que corrió.
4. Al responder, decí qué tabla, filtros y período usaste, para que la persona pueda validar el número.

Cada persona ve solo su alcance. Si una consulta no devuelve filas por permisos (por ejemplo, un asesor pidiendo tablas de mercado del sitio o de oficina), decilo y seguí con lo que sí se puede ver; no inventes ni estimes lo que falta.

## Qué tabla para cada pregunta

| Pregunta | Tabla y criterio |
|---|---|
| Operaciones cerradas, escrituras, facturación, GCI de un período | `fct_offers` con `is_signed=true` y `date_range` sobre `signed_date`. Nunca por etapa (stage) |
| Totales de la empresa u oficina | `fct_offers` |
| Rankings por asesor u oficina | `fct_offer_sides`: una operación con las dos puntas nuestras cuenta para las dos. Operaciones por oficina "como la pantalla": `is_office_operation=true` |
| GCI | `sum(signed_commission_usd)` |
| Net revenue ("GCI neto", "lo que se queda Mudafy") | `sum(net_revenue_usd)` con `is_signed=true` y `signed_date` (`fct_offers` para totales, `fct_offer_sides` por oficina o asesor). Es el GCI por el revenue share de la oficina a la fecha de firma |
| Casos / leads | `fct_cases`. Origen = `case_origin` (detalle) u `origin_group` (grupo), nunca `contact_source`. El embudo excluye `is_merged=true` |
| Visitas / tareas de asesores | `fct_visits` (por `visit_date`; hechas = `status` completed), `fct_tasks` (`status`, `is_overdue`, `days_to_complete`). Antes del 9-sep-2026 vienen migradas del sistema anterior |
| Tráfico de mudafy.com (Search Console, leads del marketplace, visitas, bots de IA, cambios SEO) | Tablas `fct_marketplace_*`. Son de todo el sitio, sin oficina; las ven super admins y regionales. Search Console llega con 2-3 días de atraso |
| Mercado y precios por zona | `rep__zone_*`, `rep__sale_comps`, `rep__block_*`, `rep__partido_*`. Son de mercado, no de una oficina (`office_ids` no aplica) y las ve cualquiera con acceso |
| Gestión de oficina | Ver abajo |

## Trampas que cambian el resultado

- **Montos**: sumá siempre las columnas `_usd`. Las que no terminan en `_usd` están en la moneda de cada operación (ARS, USD, MXN) y no se pueden sumar entre sí. Los montos MXN originales no están disponibles.
- **Parciales**: el mes en curso y el anterior se siguen completando. Avisalo siempre y marcalos "(parcial)".
- **Total de la red Mudafy**: filtrá `is_mudafy_network=true` (y `office_is_test=false`). Sin eso se suma toda la base, incluidas inmobiliarias externas del MLS.
- **Casos creados "como la pantalla"** = `is_mudafy_network=true` MÁS los de `office_id` vacío (leads sin oficina). El filtro no admite "A o B": hacé dos consultas y sumalas.
- **Zonas** (barrio, ciudad, provincia): ubicalas en `fct_locations` con `contains` sobre `name` y usá su `location_id` y `zone_level` contra las tablas `rep__zone_*` y los `location_*_id` de las operaciones.
- **Tablas por zona** (`rep__zone_*`): exigen filtrar `level` (o `zone_level`) con `eq`/`in`. Sin eso se cuenta cada zona tres veces. Son percentiles ya calculados: no los sumes ni los promedies entre zonas. No mezcles monedas (`*_usd_*` son comparables; `*_local_*` van en la moneda del mercado).
- `rep__zone_price_drops` cambió de régimen el 9-sep-2026: no saques tendencias de ahí.
- **Gestión de oficina** (tablas `rep__*` con oficina; las ve cada director en sus oficinas):
  - inventario activo y su performance: `rep__inventory`, `rep__inventory_performance`;
  - captación y rotación: `rep__captacion_rotacion` (+ `rep__captaciones_detalle` para la lista y `rep__dias_a_escritura` para los días);
  - casos abiertos hoy: `rep__cases_open` (evolución diaria en `rep__cases_open_by_stage`, creación en `rep__cases_trend`, ticket en `rep__cases_created_price`);
  - portales y destaques Super: `rep__portal_publications`, `rep__destaque_consumo`, `_episodios`, `_uso`;
  - stock vs demanda por segmento: `rep__mls_demand` (tendencia del ticket en `rep__mls_*_ticket_trend`).
  - Estas tablas exigen filtrar `network_key` (casi siempre `'mudafy'`; sin eso se cuenta doble) o `scope_kind` (`'org'` para oficinas). Las de formato largo (`rep__agent_analysis`, `rep__network_scorecards`) también exigen `metric`.
  - Para totales de operaciones o GCI seguí usando `fct_offers`.

## Antes de entregar

- Cruzá el total con otra vista cuando puedas (por ejemplo, la suma por mes contra el total del período).
- Si el número parece raro, revisá primero: ¿faltó `is_signed`? ¿se sumó una columna sin `_usd`? ¿falta `network_key` o `level`? ¿entró el mes parcial?
- Mostrar el resultado siguiendo el skill `mudafy-informes`. En el texto final no uses nombres de tablas ni de columnas.
