#! /bin/bash

#############################################################
#
# Isaías Gätjens M.
# Twitter: @igatjens
# Email: igatjens@gmail.com
#
# Ejecute este script en la carpeta donde extrajo
# los .deb que descargó de libreoffice.org.
#
# Genera la lista de «Depends: » de control del
# nuevo metapaquete para instalar LibreOffice para 
# la Tienda Deepines.
#
# La lista se guarda en el archivo «depends.txt»
#
############################################################

IFS='

'

LISTA=""

#Obtener la lista de paquetes de libreoffice.org
LISTA="${LISTA} $( find . -type f -name  "*.deb" -exec dpkg-deb --show {} \; | sort | cut -f1 \
| sed -e "s|$|,|" )"

echo ${LISTA} | tr -s [:blank:] | sed -e "s|^ ||; s|,$||" > depends.txt
cat depends.txt