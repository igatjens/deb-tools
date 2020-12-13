#! /bin/bash

IFS='
'

REGISTRO=""
CARPETA_REPORTES=$HOME/deb-reporte-problemas/
FECHA_REPORTE=$(date +%Y-%m-%d_%H.%M.%S)
ARCHIVO_REPORTE="${CARPETA_REPORTES}${FECHA_REPORTE}.txt"

analizar_deb () {
	
	ARCHIVO=$@
	PROBLEMAS=false

	#si no es un archivo .deb
	if [[ $(echo $ARCHIVO | grep -Ev ".deb$|.DEB$") ]]; then
		
		echo Error: El archivo $ARCHIVO no es un .deb
		return 1
	fi

	echo Analizando "$ARCHIVO"

	COMPLEJO=false
	PROPI_NO_ROOT=false
	OTROS_ESCRIBIR=false
	ETIQUETAS=""

	LISTA=$(dpkg-deb --contents $ARCHIVO)
	LASTA_COMPLEJO=$(echo "$LISTA" | grep -Ev " ./bin/| ./etc/| ./lib/| ./opt/| ./sbin/| ./usr/| ./tmp/| ./var/tmp/| ./$")
	LISTA_NO_ROOT=$(echo "$LISTA" | grep -Ev " root/root | 0/0 ")
	LISTA_OTROS_ESCRITURA=$(echo "$LISTA" | grep -E "^(d|-).......w. " )

	if [[ $LISTA_NO_ROOT ]]; then

		ETIQUETAS="R;"
		PROBLEMAS=true
	else
		ETIQUETAS="-;"
	fi


	if [[ $LISTA_OTROS_ESCRITURA ]]; then
		
		ETIQUETAS="${ETIQUETAS}E;"
		PROBLEMAS=true
	else
		ETIQUETAS="${ETIQUETAS}-;"
	fi


	if [[ $LASTA_COMPLEJO ]]; then

		ETIQUETAS="${ETIQUETAS}C;"
	else
		ETIQUETAS="${ETIQUETAS}-;"
	fi


	if [[ $PROBLEMAS == true ]]; then
		echo "${ETIQUETAS}${ARCHIVO}" >> "$ARCHIVO_REPORTE"
		REGISTRO=$(echo -e "${REGISTRO}\n${ETIQUETAS}${ARCHIVO}")
	fi

	return 0
}

buscar_deb () {
	echo Buscando archivos .deb en $@
	LISTA_ARCHIVOS=$(find "$@" -type f -iname  "*.deb")

	for i in $LISTA_ARCHIVOS; do
		
		analizar_deb "$i"
	done

	return 0
}


mkdir -p "$CARPETA_REPORTES"

for i in "$@"; do
	if [[ -f "$i" ]]; then

		analizar_deb "$i"
	elif [[ -d "$i" ]]; then
		
		buscar_deb "$i"
	else
		echo $i no existe.
	fi
done

#eliminar el salto de línea de la primera línea
REGISTRO=$(echo "$REGISTRO" | sed "1d")

echo -e "\n--------------------------------------"
echo Resultados
echo -e "$REGISTRO" | sed -e "s|^| |; s|;|  |g" 
echo -e "\n"
echo R: Archivos o carpetas con proietario direfente a «root»
echo E: Archivos o carpetas en que cualquiera puede escribir
echo C: El paquete extrae archivos o carpetas en ubicaciones inusuales
echo -e "\n"
echo Reporte guardado en $ARCHIVO_REPORTE
