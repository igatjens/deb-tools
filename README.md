# deb-tools
Herramientas para crear, mantener, auditar y administrar archivos deb

# Modo de uso

## Buscar

`deb-tools-permck archivo|carpeta`

Puede especificar varios archivos y varias carpetas

Analiza archivos .deb en busca de problemas de permisos y genera un informe escrito.

## Reparar

`deb-tools-permfix [-i] archivo|carpeta`

-i Modo interactivo

Analiza archivos .deb en busca de problemas de permisos, corrige los problemas y genera un nuevo archivo .deb en `~/deb-tools/reempaquetados/`

## Corregir nombre

`deb-tools-namefix archivo|carpeta`

Puede especificar varios archivos y varias carpetas.

Corrige el nombre al formato `paquete_versión_arquitectura.deb`.
