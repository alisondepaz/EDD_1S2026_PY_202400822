# Manual de Usuario — EDD MedTrack F2

**Hospital General San Carlos**

---

## 1. Iniciar el Sistema

Abra una terminal en la carpeta del proyecto y ejecute:
```bash
perl main.pl
```

---

## 2. Pantalla de Inicio

Tiene tres pestañas:

### Pestaña "Iniciar Sesión"
- **Número de Colegio:** su número de colegio (ej. `COL-00051`) o `AdminHospital`.
- **Contraseña:** su contraseña institucional.
- Presione **Ingresar al Sistema** o Enter.
- Si las credenciales son incorrectas aparece el aviso correspondiente.

**Credenciales de administrador:**
- Usuario: `AdminHospital`
- Contraseña: `MedTrack2025`

### Pestaña "Registro"
1. Complete: número de colegio, nombre, tipo de usuario, departamento,
   especialidad (opcional para TIPO-03 y TIPO-04), contraseña.
2. Presione **Registrar Usuario**.
3. Si el número de colegio ya existe, el sistema lo notifica y cancela el registro.

### Pestaña "Información del Sistema"
Muestra la tarjeta con información del desarrollador.

---

## 3. Panel de Administrador

Credenciales: `AdminHospital` / `MedTrack2025`

### Inicio / Resumen
Vista de bienvenida. Seleccione cualquier sección en el menú lateral.

### Equipos (BST)

**Insertar equipo:**
1. Complete: Código, Nombre, Fabricante, Precio, Cantidad, Fecha Ingreso, Nivel Mínimo.
2. Presione **Insertar**.

**Buscar equipo:**
1. Escriba el código en el campo Código.
2. Presione **Buscar** — aparece un mensaje con los datos.

**Eliminar equipo:**
1. Escriba el código.
2. Presione **Eliminar**.

**Ver recorridos:**
Seleccione In-Orden, Pre-Orden o Post-Orden y presione **Ver Recorrido**.
La tabla principal muestra siempre In-Orden.

### Suministros (Árbol B)
Mismas operaciones que Equipos. El campo de fecha es Fecha de Vencimiento.
Solo tiene recorrido In-Orden.

### Medicamentos
Vista de solo lectura de la lista doblemente enlazada.
Muestra todos los medicamentos cargados ordenados por código.

### Personal Médico (AVL)

**Buscar:** escriba el número de colegio y presione **Buscar**.

**Eliminar:** escriba el número de colegio y presione **Eliminar**.
El árbol rebalancea automáticamente.

**Filtrar:** seleccione un departamento y presione **Filtrar**.

**Recorridos:** igual que en BST (In-Orden, Pre-Orden, Post-Orden).

### Carga Inventario JSON
1. Presione **Seleccionar Archivo JSON**.
2. Elija el archivo `.json` con estructura de proveedores.
3. El sistema muestra en pantalla cuántos ítems se insertaron y
   qué errores hubo (con el código del ítem problemático).
4. Las tablas se actualizan automáticamente.

**Errores que NO detienen la carga:**
- Ítem sin código o nombre
- Cantidad cero o negativa
- Tipo de ítem desconocido
- Número de colegio duplicado en usuarios

### Carga Usuarios JSON
Igual que carga de inventario, pero con estructura `{ "usuarios": [...] }`.

### Matriz Proveedor / Fabricante
Tabla donde filas = proveedores, columnas = fabricantes.
Cada celda muestra la cantidad total entregada. Solo aparecen celdas > 0.

### Reportes Graphviz

| Botón | Reporte |
|-------|---------|
| Árbol AVL | Personal médico, nodos circulares |
| Árbol BST | Equipos, nodos rectangulares |
| Árbol B Ord. 4 | Suministros, bloques segmentados |
| Matriz Dispersa | Red proveedor-fabricante-cantidad |
| Medicamentos | Lista doble horizontal |
| Proveedores | Lista circular doble |

Al presionar:
1. Se genera el `.dot` y Graphviz produce el PNG.
2. El reporte aparece en la parte inferior de la pantalla.
3. El PNG queda guardado en la carpeta `reportes/`.

---

## 4. Panel de Usuario Médico

El menú lateral solo muestra las secciones permitidas para su departamento.

### Inicio
Datos del usuario y módulos disponibles para su departamento.

### Consultar Medicamentos *(DEP-MED, DEP-FAR)*
- Escriba el código y presione **Buscar**.
- Muestra nombre, principio activo, cantidad y fecha de vencimiento.
- Si la cantidad está bajo el nivel mínimo: **⚠ STOCK BAJO DEL NIVEL MÍNIMO**.
- La tabla inferior muestra todos los medicamentos con su estado.

### Consultar Equipos *(DEP-CIR, DEP-LAB)*
- Escriba el código y presione **Buscar en BST**.
- Muestra nombre, fabricante, precio, cantidad, fecha de ingreso.

### Consultar Suministros *(DEP-MED, DEP-CIR)*
- Escriba el código y presione **Buscar en Árbol B**.
- Muestra nombre, fabricante, precio, cantidad, fecha de vencimiento.
- Alerta si la cantidad está bajo el nivel mínimo.

### Mi Perfil
- Puede editar su **nombre** y **contraseña**.
- Presione **Guardar Cambios** para confirmar.

---

## 5. Cerrar Sesión

Presione **Cerrar Sesión** en la parte inferior del menú lateral.
El sistema regresa a la pantalla de login.

---

## 6. Preguntas Frecuentes

**¿Qué pasa si cargo un JSON con código ya existente?**
El sistema actualiza los datos del ítem, sin duplicar.

**¿Qué pasa si un usuario tiene número de colegio repetido?**
El sistema reporta la advertencia en el log y no inserta el duplicado.
El primero que se procesó queda registrado.

**¿Los datos se guardan al cerrar?**
No. Los datos viven en memoria. Para persistirlos, mantenga los archivos
en `datos/` — se recargan automáticamente al iniciar.

**¿Por qué no aparece el reporte?**
Verifique que Graphviz esté instalado: `dot -V` en la terminal.
Si no está: `sudo apt install graphviz`.