/*==============================================================================
TALLER INTRODUCTORIO EN STATA APLICADO A CIENCIAS SOCIALES
Tarea 2
Integrantes: 

Luis Martínez
Elizabeth García
Margareth Rodríguez
Antonio Macedo
==============================================================================*/
clear all
cls

global main "C:\Users\User\OneDrive\0_BE\Descargas\1 Stata\grupo_1"     // <-- CAMBIAR
global data "$main/Data"
global procesada "$main/Procesada"
global graficos "$main/Graficos"
global output "$main/Output"

capture ssc install outreg2
capture ssc install estout

*===============================================================================
* PARTE 1: CONSTRUCCIÓN DE VARIABLES Y ANÁLISIS GRÁFICO (Sumaria ENAHO 2024)
*===============================================================================

use "$data/sumaria-2024.dta", clear

* 1.1 Construcción de variables solicitadas
* Ingreso per cápita mensual (inghog2d / (mieperho * 12))
* inghog2d es el ingreso ANUAL del hogar, por eso lo dividimos entre 12 
* para pasarlo a mensual, y entre mieperho para que sea por persona (per cápita)
gen ipc = inghog2d / (mieperho * 12)
label var ipc "Ingreso per cápita mensual (S/)"

* Gasto per cápita mensual (gashog2d / (mieperho * 12))
gen gpc = gashog2d / (mieperho * 12)
label var gpc "Gasto per cápita mensual (S/)"

* Área: 1 = Urbano (estratos 1 a 6), 2 = Rural (estratos 7 a 8) Usamos estrato para definir área urbana/rural
gen area = .
replace area = 1 if estrato >= 1 & estrato <= 6
replace area = 2 if estrato >= 7 & estrato <= 8
label define lbl_area 1 "Urbano" 2 "Rural"
label values area lbl_area
label var area "Área de residencia"

* necesitamos armar esto desde ubigeo. dominio==8 es Lima Metropolitana y ahí también entra Callao

gen zona = .
replace zona = 4 if dominio == 8                    // Lima Metropolitana (incluye Callao)
replace zona = 1 if dominio >= 1 & dominio <= 3 & zona==.  // Costa
replace zona = 2 if dominio >= 4 & dominio <= 6 & zona==.  // Sierra
replace zona = 3 if dominio == 7 & zona==.                 // Selva
label define lbl_zona 1 "Costa" 2 "Sierra" 3 "Selva" 4 "Lima Metropolitana"
label values zona lbl_zona
label var zona "Zona geográfica"

* 1.2 Gráficos y exportación
* Histograma del ingreso per cápita
* - El ingreso tiene varios outliers bien altos (hogares con S/ 50,000+) que estiran el eje X y comprimen todo lo demás en una sola barrita

histogram ipc if ipc < 5000, frequency color(navy%80) ///
    title("Distribución del Ingreso Per Cápita Mensual") ///
    xtitle("Ingreso per cápita (S/)") ytitle("Frecuencia")
graph export "$graficos/histograma_ipc.png", as(png) replace

* Gráfico de barras: Ingreso per cápita promedio por zona

graph bar (mean) ipc, over(zona) bar(1, color(teal%85)) blabel(bar, format(%9.1f)) ///
    title("Ingreso Per Cápita Promedio por Zona Geográfica") ///
    ytitle("Ingreso medio mensual (S/)")
graph export "$graficos/barras_ipc_zona.png", as(png) replace

* Gráfico de densidad de Kernel: Comparación Urbano vs. Rural
* metemos las 2 curvas (urbano y rural) en el mismo twoway para poder compararlas directo en un solo gráfico

twoway (kdensity ipc if area == 1 & ipc < 4000, color(navy) lwidth(medium) lpattern(solid)) ///
       (kdensity ipc if area == 2 & ipc < 4000, color(maroon) lwidth(medium) lpattern(dash)), ///
    title("Densidad del Ingreso Per Cápita: Urbano vs. Rural") ///
    xtitle("Ingreso per cápita (S/)") ytitle("Densidad") ///
    legend(order(1 "Urbano" 2 "Rural"))
graph export "$graficos/densidad_ipc_area.png", as(png) replace

*===============================================================================
* PARTE 2: REGRESIÓN LINEAL MCO
*===============================================================================

* Regresión lineal de gpc
* - Esto ayudará a visualizar cómo cambia el gasto del hogar cuando cambia su ingreso
regress gpc ipc mieperho i.area i.zona

regress gpc ipc mieperho i.area i.zona

* Exportar resultados
outreg2 using "$output/tabla_mco.doc", replace word dec(3) ///
    title("Regresión MCO: Determinantes del Gasto Per Cápita")
	
	
*===============================================================================
* PARTE 3: MODELO DE ELECCION BINARIA
*===============================================================================
use "$data/base_salud_tarea1.dta", clear
gen edad = p208a

* 3.1.1 Modelo logit 

logit af_salud mujer edad zona
estimates store Logit

* 3.1.2 Modelo probit 

probit af_salud mujer edad zona
estimates store Probit

* 3.1.1 Modelo logit 

quietly logit af_salud mujer edad zona
margins, dydx(*)

* 3.1.2 Modelo probit

quietly probit af_salud mujer edad zona
margins, dydx(*)

*==========================================================================
* PARTE 4:  Interpretacion de resultados
*==========================================================================

* 4.1 Interpretacion MCO

* Ante una variación, de un sol en el ipc, el gpc aumenta en un 0.423.
* Ademas, se puede observar que al 5%, e incluso al 1%, todas las variables son significativas
* Las tablas en derivada  se interpretan en relacino a la variable cero como puntos porcentaules no cambios porcentuales 


* 4.2 Interpretacion LOGIT y PROBIT
* En el modelo Logit, la mujer tiene un efecto positivo en la probabilidad de estar asegurada respecto del hombre. 
* Todas las variables son significativas al 5%, y el aumento de edad aumenta la probabilidad de tener seguro,
* mientras que la zona actúa como limitante o barrera. Por otra parte, la probabilidad de estar asegurada dado que es mujer
* es de 4.13764% puntos porcentuales que la del hombre;
* y la probabilidad de estar asegurado aumenta en un 0.07262% puntos porcentuales por cada año de edad adicional


esttab Logit Probit, se mtitles scalars(N) sfmt(%10.3f) ///
    star(* 0.1 ** 0.05 *** 0.01)

outreg2 [Logit Probit] using "$output/Logit_Probit_af_salud.doc", replace word

* Las conclusiones cualitativas no cambian en absoluto.
* Ambos modelos identifican la misma dirección en las relaciones y la misma estructura de significancia estadística: 
* ser mujer y un incremento en la edad aumentan la probabilidad de aseguramiento ($p < 0.01$),
* mientras que la variable zona ejerce un efecto restrictivo ($p < 0.05$).
* La disparidad en la magnitud de los coeficientes, Logit aproximadamente 2 veces mayor que Probit, 
* se debe a una diferencia de escala parametral en los términos de error
