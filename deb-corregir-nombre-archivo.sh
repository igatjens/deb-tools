#! /bin/bash

IFS='
'

corregir_nombre () {

	ARCHIVO=$@

	#si no es un archivo .deb
	if [[ $(echo $ARCHIVO | grep -Ev ".deb$|.DEB$") ]]; then
		
		echo Error: El archivo $ARCHIVO no es un .deb
		return 1
	fi

	INFO_PAQUETE=$(dpkg-deb -f "$ARCHIVO" package version architecture | cut -d " " -f2)
	NOM_PAQUETE=$(echo $INFO_PAQUETE | cut -d " " -f1)
	VER_PAQUETE=$(echo $INFO_PAQUETE | cut -d " " -f2)
	ARQUI_PAQUETE=$(echo $INFO_PAQUETE | cut -d " " -f3)

	NUEVO_NOMBRE="$(dirname "$ARCHIVO")/${NOM_PAQUETE}_${VER_PAQUETE}_${ARQUI_PAQUETE}.deb"

	if [[ "$ARCHIVO" != "$NUEVO_NOMBRE" ]]; then
		mv "$ARCHIVO" "$NUEVO_NOMBRE"
		echo -
		echo "$ARCHIVO"
		echo ↓
	    echo "$NUEVO_NOMBRE"
	    echo -
	fi
}


buscar_deb () {
	echo Buscando archivos .deb en $@
	LISTA_ARCHIVOS=$(find "$@" -type f -iname  "*.deb")

	for i in $LISTA_ARCHIVOS; do
		
		corregir_nombre "$i"
	done

	return 0
}


for i in "$@"; do
	if [[ -f "$i" ]]; then

		corregir_nombre "$i"
	elif [[ -d "$i" ]]; then
		
		buscar_deb "$i"
	else
		echo $i no existe.
	fi
done