# Guia de conexion Airbyte -> MySQL usando `bore` y `ngrok`

## 1) Objetivo

Esta guia explica que poner en **Airbyte** cuando quieres conectar una fuente `MySQL` que esta en tu maquina o en tu red local, pero `Airbyte` no puede verla directamente.

Se cubren dos casos:

- `bore`
- `ngrok`

---

## 2) Idea general

Si `Airbyte` esta fuera de tu red, no debes poner:

- `localhost`
- `127.0.0.1`
- IP privada local

En ese caso primero abres un tunel TCP:

- `bore`
- `ngrok`

y luego en Airbyte pones:

- el `host` publico del tunel
- el `port` publico del tunel

**Importante**

En Airbyte:

- `SSH Tunnel Method` = `No Tunnel`

Porque `bore` y `ngrok` **no se configuran como tunel SSH dentro de Airbyte**.
Se usan como tuneles externos.

---

## 3) Campos de Airbyte que vas a llenar

En la fuente `MySQL` de Airbyte veras algo asi:

- `Source name`
- `Host`
- `Port`
- `User`
- `Password`
- `Database`
- `Encryption`
- `SSH Tunnel Method`
- `Update Method`

La forma correcta de llenarlos cambia solo en `Host` y `Port` segun el tunel.

---

## 4) Conexion con `bore`

## 4.1 Comando base

Ejemplo:

```bash
bore local 3306 --to bore.pub

bore local 3306 --to bore.pub --port 1111
```

o si usas tu propio servidor:

```bash
bore local 3306 --to TU_HOST_BORE
```

Cuando el tunel queda abierto, `bore` te devuelve un puerto publico.

Ejemplo ilustrativo:

- `bore.pub:41827`

## 4.2 Que poner en Airbyte

Si `bore` te devolvio:

- `bore.pub:41827`

entonces en Airbyte pones:

- `Source name`: `MySQL`
- `Host`: `bore.pub`
- `Port`: `41827`
- `User`: `Patito`
- `Password`: tu clave real de MySQL
- `Database`: tu base real de MySQL
- `Encryption`: sin SSL si MySQL no tiene SSL configurado
- `SSH Tunnel Method`: `No Tunnel`

## 4.3 Update Method recomendado

Para la primera carga:

- `Scan Changes with User Defined Cursor`

Si luego ya tienes MySQL preparado para CDC/binlog:

- `Read Changes using Change Data Capture (CDC)`

## 4.4 Ejemplo completo

Supongamos:

- MySQL local en puerto `3306`
- base de datos: `gestion_comercial_db`
- usuario: `Patito`
- `bore` devuelve `bore.pub:41827`

Entonces en Airbyte:

- `Source name`: `MySQL`
- `Host`: `bore.pub`
- `Port`: `41827`
- `User`: `Patito`
- `Password`: `TU_PASSWORD`
- `Database`: `gestion_comercial_db`
- `Encryption`: `No SSL` o equivalente
- `SSH Tunnel Method`: `No Tunnel`
- `Update Method`: `Scan Changes with User Defined Cursor`

---

## 5) Conexion con `ngrok`

## 5.1 Comando base

Ejemplo:

```bash
ngrok tcp 3306
```

`ngrok` te mostrara una direccion publica parecida a esta:

- `tcp://1.tcp.ngrok.io:19476`

## 5.2 Que poner en Airbyte

Si `ngrok` te mostro:

- `tcp://1.tcp.ngrok.io:19476`

entonces en Airbyte pones:

- `Source name`: `MySQL`
- `Host`: `1.tcp.ngrok.io`
- `Port`: `19476`
- `User`: `Patito`
- `Password`: tu clave real de MySQL
- `Database`: tu base real de MySQL
- `Encryption`: sin SSL si MySQL no tiene SSL configurado
- `SSH Tunnel Method`: `No Tunnel`

## 5.3 Update Method recomendado

Para la primera carga:

- `Scan Changes with User Defined Cursor`

Si despues habilitas CDC/binlog:

- `Read Changes using Change Data Capture (CDC)`

## 5.4 Ejemplo completo

Supongamos:

- MySQL local en puerto `3306`
- base de datos: `gestion_comercial_db`
- usuario: `Patito`
- `ngrok` devuelve `tcp://1.tcp.ngrok.io:19476`

Entonces en Airbyte:

- `Source name`: `MySQL`
- `Host`: `1.tcp.ngrok.io`
- `Port`: `19476`
- `User`: `Patito`
- `Password`: `TU_PASSWORD`
- `Database`: `gestion_comercial_db`
- `Encryption`: `No SSL` o equivalente
- `SSH Tunnel Method`: `No Tunnel`
- `Update Method`: `Scan Changes with User Defined Cursor`

---

## 6) Que poner en `Encryption`

Eso depende de tu MySQL:

- si tu MySQL **no tiene SSL/TLS configurado**, usa la opcion sin cifrado
- si tu MySQL **si tiene SSL/TLS**, entonces eliges la opcion SSL y cargas los parametros que Airbyte te pida

Para una instalacion local normal, lo mas comun es:

- `No SSL`

---

## 7) Que poner en `Update Method`

## Opcion 1: `Scan Changes with User Defined Cursor`

Usala si quieres algo mas simple al inicio.

Normalmente eliges una columna como:

- `created_at`
- `updated_at`
- `fecha_registro`
- `fecha_creacion`

## Opcion 2: `Read Changes using Change Data Capture (CDC)`

Usala si quieres:

- inserciones
- actualizaciones
- eliminaciones

Pero requiere que MySQL tenga listo:

- binlog
- configuracion de CDC compatible

Si no estas seguro, empieza con:

- `Scan Changes with User Defined Cursor`

---

## 8) Recomendacion practica

Para tu primera conexion:

1. abre el tunel
2. usa `No Tunnel` en Airbyte
3. usa `No SSL` si tu MySQL local no tiene SSL
4. usa `Scan Changes with User Defined Cursor`
5. prueba conexion
6. recien despues evalua pasar a `CDC`

---

## 9) Resumen rapido

## Con `bore`

Si el tunel devuelve:

- `bore.pub:41827`

entonces:

- `Host` = `bore.pub`
- `Port` = `41827`
- `SSH Tunnel Method` = `No Tunnel`

## Con `ngrok`

Si el tunel devuelve:

- `tcp://1.tcp.ngrok.io:19476`

entonces:

- `Host` = `1.tcp.ngrok.io`
- `Port` = `19476`
- `SSH Tunnel Method` = `No Tunnel`

---

## 10) Observacion importante de seguridad

Para pruebas esta bien usar tuneles temporales.

Pero para uso serio o continuo:

- crea un usuario MySQL solo lectura para Airbyte
- no uses credenciales de administrador
- cierra el tunel cuando termines
- si puedes, usa tunel privado o infraestructura propia
