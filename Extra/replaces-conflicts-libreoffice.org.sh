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
# Genera la lista de «Replaces: » y «Conflicts: » para el 
# control del nuevo metapaquete para instalar LibreOffice  
# para la Tienda Deepines.
#
# La lista se guarda en «replaces.txt» y «conflicts.txt»
#
#
#  ***** IMPORTANTE *****
#
#  No olvide especificar la versión nueva y la versión vieja
#
#  ***** IMPORTANTE *****
#
############################################################

IFS='

'

VERSION_VIEJA=6.3
VERSION_NUEVA=6.4
LISTA_REPLACES=""
LISTA_CONFLICTS=""


#Obtener la lista de paquetes de libreoffice.org de la versión anterior
LISTA_REPLACES="$( find . -type f -name  "*.deb" -exec dpkg-deb --show {} \; | sort | cut -f1 \
| sed -e "s|${VERSION_NUEVA}|${VERSION_VIEJA}|; s|$|,|" )"

echo ${LISTA_REPLACES} | tr -s [:blank:] | sed -e "s|^ ||; s|,$||" > replaces.txt
echo Replaces:
cat replaces.txt

#Obtener la lista para buscar en el repositorio de Deepin
LISTA_REPO_DEEPIN="$( find . -type f -name  "*.deb" -exec dpkg-deb --show {} \; \
| sort | cut -f1 | sed "s|${VERSION_NUEVA}||" )"

for i in $LISTA_REPO_DEEPIN; do
	#statements
	LISTA_CONFLICTS="${LISTA_CONFLICTS} $( apt show "$i" 2>/dev/null | grep -E "(^Package: |^Version: )" \
	| sed -e "s|Package: ||; s|Version: | (<= |" | sed "s|^ (.*|&), |" )"
done

echo ${LISTA_CONFLICTS} | tr -s [:blank:] | sed -e "s|^ ||; s|, $||" > conflicts.txt
echo Conflicts:
cat conflicts.txt
