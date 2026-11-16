# trabajo-de-stata

Tarea 2 del **Taller introductorio en Stata aplicado a ciencias sociales** (trabajo grupal). El do-file construye variables de ingreso y gasto con la Sumaria ENAHO 2024, hace tres gráficos, estima una regresión MCO y compara un modelo logit con un probit sobre el aseguramiento en salud.

**Integrantes:** Luis Martínez, Elizabeth García, Margareth Rodríguez y Antonio Macedo.

## Requisitos

- Stata.
- Paquetes `outreg2` y `estout`. El script los instala solo con `capture ssc install`.
- Dos bases en formato `.dta`:
  - `sumaria-2024.dta` (Sumaria ENAHO 2024).
  - `base_salud_tarea1.dta` (base de la Tarea 1; usa las variables `af_salud`, `mujer`, `p208a` y `zona`).

## Estructura de carpetas esperada

Todo cuelga de la ruta `main`, definida en la línea 14 del do-file:

```
grupo_1/
├── Data/        <- sumaria-2024.dta, base_salud_tarea1.dta
├── Procesada/
├── Graficos/    <- salida de los gráficos (.png)
└── Output/      <- salida de las tablas (.doc)
```

Las carpetas deben existir antes de correr el script; no las crea.

## Antes de ejecutar

Cambia el global `main` (línea marcada con `<-- CAMBIAR`) a la ruta de tu computadora. Los demás globals (`data`, `procesada`, `graficos`, `output`) se derivan de ese.

## Qué hace, por partes

### Parte 1: variables y gráficos (Sumaria 2024)

| Variable | Definición |
|---|---|
| `ipc` | Ingreso per cápita mensual: `inghog2d / (mieperho * 12)` (`inghog2d` es anual) |
| `gpc` | Gasto per cápita mensual: `gashog2d / (mieperho * 12)` |
| `area` | 1 = Urbano (estratos 1 a 6), 2 = Rural (estratos 7 y 8) |
| `zona` | 1 = Costa (dominios 1-3), 2 = Sierra (4-6), 3 = Selva (7), 4 = Lima Metropolitana (dominio 8, incluye Callao) |

Gráficos exportados a `Graficos/`:

- `histograma_ipc.png`: histograma del ingreso per cápita, recortado a `ipc < 5000` por los valores extremos.
- `barras_ipc_zona.png`: ingreso per cápita promedio por zona.
- `densidad_ipc_area.png`: densidades kernel urbano vs. rural, recortadas a `ipc < 4000`.

### Parte 2: regresión MCO

`regress gpc ipc mieperho i.area i.zona`, exportada a `Output/tabla_mco.doc` con `outreg2` (3 decimales).

### Parte 3: modelos de elección binaria

Con `base_salud_tarea1.dta`: se crea `edad` a partir de `p208a` y se estiman un logit y un probit de `af_salud` sobre `mujer`, `edad` y `zona`. Los modelos se guardan como `Logit` y `Probit`, y se calculan los efectos marginales con `margins, dydx(*)`.

### Parte 4: interpretación

Comentarios dentro del do-file con la lectura de los resultados MCO y de logit/probit. Después se genera la tabla comparativa:

- `esttab Logit Probit` en pantalla, con errores estándar y estrellas de significancia.
- `Output/Logit_Probit_af_salud.doc` con `outreg2`.

## Salidas

| Archivo | Carpeta |
|---|---|
| `histograma_ipc.png`, `barras_ipc_zona.png`, `densidad_ipc_area.png` | `Graficos/` |
| `tabla_mco.doc`, `Logit_Probit_af_salud.doc` | `Output/` |

## Observaciones sobre el código

- La regresión MCO (`regress gpc ipc mieperho i.area i.zona`) aparece escrita dos veces seguidas; con una basta.
- Los bloques de logit y probit se repiten: primero para guardar los modelos y luego en modo `quietly` para los efectos marginales. Además, los dos encabezados "3.1.1" y "3.1.2" están duplicados.
- En el logit y el probit, `zona` entra como variable continua (sin `i.`), a diferencia de la regresión MCO. Conviene confirmar que es lo que se busca, porque `zona` es categórica.
- Las cifras citadas en los comentarios de interpretación (0.423, 4.13764, 0.07262) están escritas a mano; no se generan al ejecutar el script.
- `Procesada/` está definida como global pero no se usa.
