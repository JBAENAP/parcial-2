# Parcial 2 - Programación III

Universidad del Quindío - Programación funcional con Elixir.

Problemas elegidos: **1 (Rutas de entrega en una red dirigida)** y **2 (Regiones en un mapa de colores y exportación SVG)**.
Con esta combinación se cumple la regla del enunciado: el problema 1 tiene Stream infinito y los dos usan structs.

## Requisitos

- Elixir 1.14 o superior (probado con Elixir 1.20 / OTP 29). No se necesitan dependencias.

## Cómo ejecutar

```bash
cd problema1
elixir main.exs                  # usa tramos.csv y consultas.txt de la carpeta
elixir main.exs casos/invalido   # usa los archivos de otra carpeta

cd ../problema2
elixir main.exs                  # usa mapa.txt y paleta.csv de la carpeta
elixir main.exs casos/especiales
```

Las salidas se crean (o se reemplazan) en la misma carpeta de las entradas.

## Estructura

```
comun.exs            lectura con File.stream!, escritura línea por línea y escape XML
problema1/
  tramo.exs          %Tramo{} y Tramo.parse/1
  itinerario.exs     %Itinerario{}
  depuracion.exs     validación recursiva (quita bucles y parejas repetidas)
  alcance.exs        Stream infinito de centros alcanzables
  busqueda.exs       búsqueda recursiva de itinerarios simples y criterios óptimos
  main.exs           programa principal
problema2/
  color.exs          %Color{}
  region.exs         %Region{}
  validacion.exs     validación recursiva del mapa y la paleta
  regiones.exs       búsqueda recursiva de regiones, área, perímetro y caja
  svg.exs            exportación a SVG por partes
  main.exs           programa principal
```

## Cómo se cumplen los requisitos generales

| Requisito | Dónde |
|---|---|
| Lectura con `File.stream!/1` | `Comun.leer_lineas/2`. No se usa `File.read!` en ninguna parte. |
| Transformaciones perezosas | `Stream.with_index`, `Stream.map` y `Stream.reject`. El stream se consume una sola vez al final. |
| Comentarios y líneas en blanco | Se ignoran las líneas que, sin espacios, empiezan por `#` o quedan vacías. Cada línea lleva su número físico original. |
| Salidas por flujo | `File.open!` + `IO.puts` línea por línea. El SVG se escribe en orden: encabezado, rectángulos, textos y cierre. |
| Pantalla y archivo | En pantalla van los resúmenes; en los archivos, el detalle. |
| Archivos faltantes | `Comun.verificar_archivos/2` dice cuál falta y el programa termina sin excepción. |
| Validación recursiva sin Enum/Stream | `Depuracion` (P1) y `Validacion` (P2): solo recursión, `Map`, `String` y `length`. |

## Problema 1 - Rutas de entrega

Entradas: `tramos.csv` (`origen,destino,minutos,costo`) y `consultas.txt` (`origen,destino`).

Salidas:
- `itinerarios.txt`: un bloque por consulta. Cada itinerario va numerado, con sus centros, los tramos usados, el tiempo y el costo. Al final del bloque están los mejores itinerarios por menos tramos, menor tiempo y menor costo, con empates.
- `errores_tramos.txt`: líneas mal formadas (cantidad de campos, números no enteros o no positivos, centros vacíos).
- `depuracion_tramos.txt`: tramos descartados por ser bucles (`A,A`) o parejas repetidas. Se conserva la primera aparición.
- `alcance_centros.txt`: los estados del Stream infinito y el paso donde se estabiliza.

Decisiones:
- Un centro "existe" si aparece en algún tramo bien formado, aunque ese tramo se descarte después en la depuración.
- Si el origen es igual al destino, hay un único itinerario de 0 tramos.
- Si el destino no queda en el conjunto final de alcanzables, se escribe "sin itinerarios" y no se hace la búsqueda.

### ¿Por qué converge el Stream infinito?

`Stream.iterate` genera los pasos sin fin, pero es perezoso: solo calcula un paso cuando alguien lo pide.
Cada paso contiene al anterior, porque solo se agregan centros y nunca se quitan. Como la red tiene una cantidad finita de centros (n), el conjunto puede crecer como mucho n − 1 veces.
Después de eso, el siguiente paso es igual al anterior. En ese momento `Enum.reduce_while` hace `:halt` y no se piden más pasos.
El consumo, por lo tanto, es de a lo sumo n + 1 pasos.

## Problema 2 - Regiones y SVG

Entradas: `mapa.txt` (símbolos separados por espacios) y `paleta.csv` (`simbolo,nombre,color_hex`).

Salidas:
- `validacion_mapa.txt`: todos los problemas encontrados, con línea, fila y columna. Si hay errores no se calculan regiones y se borran las salidas viejas.
- `regiones.csv`: `id;simbolo;area;perimetro;desde;hasta`.
- `mapa_regiones.svg`: casillas de 40×40 con el color de la paleta, borde y el ID de la región en su primera casilla. Al pasar el mouse sobre una casilla se ve un título con la región y el nombre del color.
- `resumen_regiones.txt`: número de regiones y las de mayor área y mayor perímetro, con empates.

Decisiones:
- Las líneas en blanco al inicio o al final de `mapa.txt` se ignoran, como dice la regla general. Una línea en blanco entre dos filas se reporta como "fila vacía".
- Un símbolo de paleta no puede ser `#`, porque esa línea se tomaría como comentario.
- Todo texto que entra al SVG pasa por `Comun.escapar_xml/1`.

## Casos de prueba

| Carpeta | Qué prueba |
|---|---|
| `problema1/` | Ejemplo del enunciado: 4 itinerarios de A a D; B → A sin itinerarios. |
| `problema1/casos/invalido` | Campos faltantes o de más, texto en lugar de número, negativos, cero, centro vacío, pareja repetida, consultas mal escritas y centros inexistentes. |
| `problema1/casos/limite` | Origen = destino, ciclo, tramos en ambos sentidos, centro que solo aparece en un bucle. |
| `problema1/casos/vacio` | Archivo solo con comentarios. |
| `problema1/casos/grande` | Grafo dirigido completo de 7 centros: 326 itinerarios por consulta. |
| `problema1/casos/faltante` | Falta `consultas.txt`. |
| `problema2/` | Ejemplo del enunciado: 4 regiones. |
| `problema2/casos/invalido` | Filas de distinto largo, símbolo sin color, hex inválido, símbolo repetido, línea con 2 campos, falta `.`. |
| `problema2/casos/fila_vacia` | Fila vacía en medio del mapa. |
| `problema2/casos/limite_1x1` | Mapa de una sola casilla. |
| `problema2/casos/todo_fondo` | Mapa sin regiones (solo `.`). |
| `problema2/casos/especiales` | Símbolos `&` y `<` y nombres con comillas: prueba el escape XML. |
| `problema2/casos/grande` | Tablero de ajedrez de 20×20: 400 regiones empatadas. |
| `problema2/casos/bloque_grande` | Una sola región de 60×60 (3600 casillas) para probar la recursión profunda. |
| `problema2/casos/faltante` | Falta `mapa.txt`. |
