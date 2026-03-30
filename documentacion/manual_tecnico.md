# Manual Técnico — EDD MedTrack F2

**Curso:** Estructuras de Datos  
**Universidad:** Universidad de San Carlos de Guatemala  
**Facultad:** Ingeniería en Ciencias y Sistemas  
**Lenguaje:** Perl 5 con GTK3  
**Reportes:** Graphviz (dot)

---

## 1. Descripción General

EDD MedTrack Fase 2 es un sistema de gestión hospitalaria que incorpora estructuras
de datos no lineales (Árbol BST, Árbol AVL, Árbol B de Orden 4), control de acceso
diferenciado por departamento, y reportes gráficos generados con Graphviz.

---

## 2. Estructura de Archivos
```
EDD_Proyecto1_Fase2/
├── main.pl                    Punto de entrada. Inicializa estructuras y lanza el login.
├── lib/
│   ├── ArbolAVL.pm            AVL autobalanceado. Personal médico por número de colegio.
│   ├── ArbolBST.pm            BST. Equipos médicos por código.
│   ├── ArbolB.pm              Árbol B Orden 4. Suministros médicos.
│   ├── ListaDoble.pm          Lista doblemente enlazada. Medicamentos.
│   ├── ListaCircularDoble.pm  Lista circular doblemente enlazada. Proveedores.
│   ├── MatrizDispersa.pm      Matriz dispersa. Proveedor vs fabricante.
│   ├── CargadorJSON.pm        Carga masiva desde JSON con validación.
│   └── Reportes.pm            Genera .dot y ejecuta Graphviz → PNG.
├── gui/
│   ├── VentanaLogin.pm        Login, registro e info del desarrollador.
│   ├── PanelAdmin.pm          Panel completo del administrador.
│   └── PanelUsuario.pm        Panel de usuario médico con permisos.
├── datos/
│   ├── archivo1.json          JSON de inventario (proveedores y entregas).
│   └── archivo2.json          JSON de usuarios departamentales.
├── reportes/                  Carpeta donde Graphviz guarda los PNG generados.
└── documentacion/
    ├── manual_tecnico.md      Este archivo.
    └── manual_usuario.md      Manual de uso del sistema.
```

---

## 3. Estructuras de Datos

### 3.1 Árbol AVL (`lib/ArbolAVL.pm`)

Árbol binario autobalanceado. Almacena personal médico ordenado por número de colegio.

**Campos del nodo:** `numero_colegio` (clave), `nombre`, `tipo`, `departamento`,
`especialidad`, `contrasena`, `izq`, `der`, `altura`.

| Operación | Complejidad | Descripción |
|-----------|-------------|-------------|
| insertar  | O(log n)    | Inserta y aplica rotaciones para mantener balance |
| buscar    | O(log n)    | Recorre comparando la clave string |
| eliminar  | O(log n)    | Elimina y rebalancea; usa sucesor inorden si tiene dos hijos |
| inorden   | O(n)        | Izquierda → raíz → derecha |
| preorden  | O(n)        | Raíz → izquierda → derecha |
| postorden | O(n)        | Izquierda → derecha → raíz |

**Rotaciones:**
- Izquierda-Izquierda → rotación simple derecha
- Derecha-Derecha → rotación simple izquierda
- Izquierda-Derecha → rotación doble (izq + der)
- Derecha-Izquierda → rotación doble (der + izq)

**DOT:** nodos circulares azules (`#4fc3f7`).

---

### 3.2 Árbol BST (`lib/ArbolBST.pm`)

BST sin balanceo. Equipos médicos ordenados por código numérico.

**Campos:** `codigo` (clave numérica), `nombre`, `fabricante`, `precio`,
`cantidad`, `fecha_ingreso`, `nivel_minimo`, `izq`, `der`.

**Eliminación:** caso dos hijos usa sucesor inorden (mínimo del subárbol derecho).

**DOT:** nodos rectangulares verdes (`#a5d6a7`).

---

### 3.3 Árbol B de Orden 4 (`lib/ArbolB.pm`)

Árbol B multicamino. Cada nodo: máximo 3 claves, máximo 4 hijos.

**Invariantes:**
- Nodo no raíz: mínimo 1 clave
- Todas las hojas al mismo nivel
- Claves en cada nodo ordenadas de menor a mayor

**Inserción:** si la raíz está llena se divide antes de descender.
Si el hijo destino está lleno, se divide primero.

**Eliminación:**
- En hoja: eliminar directamente.
- En nodo interno: reemplazar con predecesor o sucesor.
- Si el hijo tiene pocas claves: redistribuir desde hermano o fusionar.

**DOT:** bloques rectangulares segmentados. Amarillo (`#fff176`) si tiene
3 claves (al límite), verde (`#a5d6a7`) si tiene espacio.

---

### 3.4 Lista Doblemente Enlazada (`lib/ListaDoble.pm`)

Medicamentos ordenados por código numérico. Cada nodo tiene punteros `ant` y `sig`.
La inserción recorre la lista hasta encontrar la posición correcta.
Si el código ya existe, actualiza los datos.

---

### 3.5 Lista Circular Doblemente Enlazada (`lib/ListaCircularDoble.pm`)

Proveedores. El último nodo apunta de vuelta a la cabeza.
`insertar_o_actualizar`: si el NIT ya existe, agrega la entrega al historial;
si es nuevo, inserta al final de la lista circular.

---

### 3.6 Matriz Dispersa (`lib/MatrizDispersa.pm`)

Relaciona proveedores (filas por NIT) con fabricantes (columnas).
Implementada con tres hashes:
- `filas`: `nit → nombre_proveedor`
- `columnas`: `fabricante → fabricante`
- `celdas`: `"nit|fabricante" → cantidad_acumulada`

Solo se almacenan celdas con valor distinto de cero.

**DOT:** filas azules, columnas verdes, valores circulares naranjas.

---

## 4. Módulo de Carga JSON (`lib/CargadorJSON.pm`)

### `cargar_inventario`
1. Lee el archivo UTF-8 y parsea con el módulo `JSON`.
2. Valida clave `proveedor`.
3. Por cada proveedor: registra en la lista circular de proveedores.
4. Por cada ítem de la entrega:
   - Valida `tipo`, `codigo`, `nombre` y `cantidad > 0`.
   - Si falta campo: agrega advertencia y continúa (no detiene la carga).
   - `MEDICAMENTO` → lista doble
   - `EQUIPO` → BST
   - `SUMINISTRO` → Árbol B
   - Actualiza la matriz dispersa con proveedor-fabricante.

### `cargar_usuarios`
1. Parsea JSON y valida clave `usuarios`.
2. Verifica que el número de colegio no exista en el AVL.
3. Si existe: reporta advertencia, no inserta.
4. Si es nuevo: inserta en el AVL.

### Casos de error manejados

| Caso | Comportamiento |
|------|----------------|
| Código duplicado en BST | Actualiza el nodo existente |
| Código duplicado en Árbol B | Actualiza la clave existente |
| ID repetido en usuarios (ej. COL-00073) | Advertencia, no inserta |
| Tipo desconocido | Advertencia con código del ítem |
| Cantidad <= 0 | Advertencia, omite el ítem |
| JSON mal formado | Error, retorna sin procesar |

---

## 5. Reportes con Graphviz (`lib/Reportes.pm`)

Cada función:
1. Llama a `generar_dot()` de la estructura.
2. Guarda el `.dot` en `reportes/nombre.dot`.
3. Ejecuta `dot -Tpng archivo.dot -o archivo.png`.
4. Retorna la ruta al PNG (o `undef` si Graphviz no está disponible).

Los PNG se muestran dentro de la interfaz del administrador.

| Reporte | Archivo PNG | Estilo visual |
|---------|-------------|---------------|
| AVL Personal | reporte_avl.png | Nodos circulares azules |
| BST Equipos | reporte_bst.png | Nodos rectangulares verdes |
| Árbol B Suministros | reporte_arbol_b.png | Bloques segmentados amarillo/verde |
| Matriz Dispersa | reporte_matriz.png | Azul + verde + naranjas |
| Medicamentos | reporte_medicamentos.png | Lista horizontal flechas dobles |
| Proveedores | reporte_proveedores.png | Lista circular horizontal |

---

## 6. Permisos por Departamento

| Código | Departamento | Tipos permitidos | Inventario |
|--------|-------------|-----------------|------------|
| DEP-ADM | Administración | TIPO-05 | TOTAL |
| DEP-MED | Medicina General | TIPO-01, TIPO-03 | MED + SUM |
| DEP-CIR | Cirugía | TIPO-02, TIPO-03 | EQU + SUM |
| DEP-LAB | Laboratorio | TIPO-04 | EQU |
| DEP-FAR | Farmacia | TIPO-03 | MED |

---

## 7. Credenciales

- **Administrador:** `AdminHospital` / `MedTrack2025`
- **Usuarios:** número de colegio + contraseña almacenada en el AVL.

---

## 8. Dependencias
```bash
sudo apt install perl libgtk-3-dev graphviz
sudo cpan install JSON Gtk3
dot -V  
```

---

## 9. Precarga Automática

Al iniciar, `main.pl` verifica si existen `datos/archivo1.json` y
`datos/archivo2.json`. Si existen, los carga antes de mostrar el login.
Los mensajes de carga se imprimen en la terminal.