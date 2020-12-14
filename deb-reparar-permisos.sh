#! /bin/bash

IFS='
'

PARAMEPTRO=""
UBICACION=""
MODO_INTERACTIVO=false

quiere_continuar () {
	TECLADO=""
	CONTINUAR=true
	while [[ $CONTINUAR == true ]]; do
		
		echo -e "\n--------------------------------------"
		echo -e "¿Quiere contiuar con el proceso de reempaquetado\? (s/N)"
		read TECLADO

		if [[ $TECLADO == "" ]]; then
			TECLADO="N"
		fi

		#echo TECLADO: $TECLADO

		case $TECLADO in
			S|s)
				CONTINUAR=false
				;;
			N|n)
				CONTINUAR=false
				exit 0
				;;
			* )
				echo Respuesta incorrecta
				;;
		esac
	done
}

reempaquetar () {
	echo Iniciando reempaquetado

	CARPETA_TRABAJO="$HOME/deb-tools/"
	CARPETA_REEMPAQUETADOS="${CARPETA_TRABAJO}reempaquetados/"
	PAQUETE="$1"

	if [[ ! "$PAQUETE" ]]; then
		echo $PAQUETE no existe
		return 1
	fi

	LISTA_QUITAR_ESCRITURA_OTROS="$2"
	INFO_PAQUETE=$(dpkg-deb -f "$PAQUETE" package version architecture | cut -d " " -f2)
	NOM_PAQUETE=$(echo $INFO_PAQUETE | cut -d " " -f1)
	VER_PAQUETE=$(echo $INFO_PAQUETE | cut -d " " -f2)
	ARQUI_PAQUETE=$(echo $INFO_PAQUETE | cut -d " " -f3)

	REEMPAQUETADO="${NOM_PAQUETE}_${VER_PAQUETE}_${ARQUI_PAQUETE}"
	CARPETA_CONSTR="${CARPETA_REEMPAQUETADOS}${REEMPAQUETADO}/"

	mkdir -p "$CARPETA_TRABAJO"
	mkdir -p "$CARPETA_REEMPAQUETADOS"

	if [[ -d "$CARPETA_CONSTR" ]]; then
		echo Borrando carpeta $CARPETA_CONSTR
		rm -rf "$CARPETA_CONSTR"
	fi

	echo Creando $CARPETA_CONSTR
	mkdir "$CARPETA_CONSTR"

	echo Extrayendo paquete $PAQUETE
	dpkg-deb -R "$PAQUETE" "$CARPETA_CONSTR"

	if [[ "$LISTA_QUITAR_ESCRITURA_OTROS" ]]; then

		echo Quitando permisos de escritura a «otros» de los siguientes archivos

		for i in $LISTA_QUITAR_ESCRITURA_OTROS; do
			chmod o-w "${CARPETA_CONSTR}""${i}"
			echo "${i}"
		done
	fi

	echo Iniciando fakeroot
	fakeroot bash -c "echo Estableciendo propietario y grupo «root» a $CARPETA_CONSTR;\
	chown -R root:root "$CARPETA_CONSTR";\
	dpkg-deb --build "$CARPETA_CONSTR" "$CARPETA_REEMPAQUETADOS";"

	echo fakeroot terminado

	echo Borrando $CARPETA_CONSTR
	rm -rf "$CARPETA_CONSTR"

	echo Reempaquetado $REEMPAQUETADO en $CARPETA_REEMPAQUETADOS$REEMPAQUETADO.deb
}

analizar_deb () {

	ARCHIVO=$@
	PROBLEMAS=false

	#si no es un archivo .deb
	if [[ $(echo $ARCHIVO | grep -Ev ".deb$|.DEB$") ]]; then
		
		echo Error: El archivo $ARCHIVO no es un .deb
		return 1
	fi

	echo -e "\n--------------------------------------"
	echo Analizando "$ARCHIVO"
	dpkg-deb -f "$ARCHIVO" package version architecture

	COMPLEJO=false
	PROPI_NO_ROOT=false
	OTROS_ESCRIBIR=false


	LISTA=$(dpkg-deb --contents $ARCHIVO)
	LiSTA_COMPLEJO=$(echo "$LISTA" | grep -Ev " ./bin/| ./etc/| ./lib/| ./opt/| ./sbin/| ./usr/| ./tmp/| ./var/tmp/| ./$")
	LISTA_NO_ROOT=$(echo "$LISTA" | grep -Ev " root/root | 0/0 ")
	LISTA_OTROS_ESCRITURA=$(echo "$LISTA" | grep -E "^(d|-).......w. " )
	LISTA_OTROS_ESCRITURA_SIMPLE=""

	if [[ $LISTA_NO_ROOT ]]; then
		PROPI_NO_ROOT=true
		PROBLEMAS=true
		echo R: Archivos o carpetas con proietario direfente a «root»
	fi


	if [[ $LISTA_OTROS_ESCRITURA ]]; then
		
		OTROS_ESCRIBIR=true
		PROBLEMAS=true
		LISTA_OTROS_ESCRITURA_SIMPLE="$(echo "$LISTA_OTROS_ESCRITURA" | tr -s [:blank:] | cut -d " " -f 6 | sed "s|^./||")"
		echo E: Archivos o carpetas en que cualquiera puede escribir
	fi


	if [[ $LiSTA_COMPLEJO ]]; then

		COMPLEJO=true
		echo C: El paquete extrae archivos o carpetas en ubicaciones inusuales
	fi

	if [[ $MODO_INTERACTIVO == true ]]; then

		if [[ $COMPLEJO == true ]]; then
			
			TECLADO=""
			CONTINUAR=true
			while [[ $CONTINUAR == true ]]; do
				
				echo -e "\n--------------------------------------"
				echo -e "Se encontraron archivos que se extraen en ubicaciones inusuales"
				echo -e "¿Quiere verlos\? (S/n)"
				read TECLADO

				if [[ $TECLADO == "" ]]; then
					TECLADO="S"
				fi

				#echo TECLADO: $TECLADO

				case $TECLADO in
					S|s)
						echo "$LiSTA_COMPLEJO" | less
						CONTINUAR=false
						;;
					N|n)
						CONTINUAR=false
						;;
					* )
						echo Respuesta incorrecta
						;;
				esac
			done
			quiere_continuar
		fi

		if [[ $PROPI_NO_ROOT == true ]]; then
			
			TECLADO=""
			CONTINUAR=true
			while [[ $CONTINUAR == true ]]; do
				
				echo -e "\n--------------------------------------"
				echo -e "Se encontraron archivos con propietario y grupo diferente a «root»"
				echo -e "¿Quiere verlos\? (S/n)"
				read TECLADO

				if [[ $TECLADO == "" ]]; then
					TECLADO="S"
				fi

				case $TECLADO in
					S|s)
						echo "$LISTA_NO_ROOT" | less
						CONTINUAR=false
						;;
					N|n)
						CONTINUAR=false
						;;
					* )
						echo Respuesta incorrecta
						;;
				esac
			done
			quiere_continuar
		fi

		if [[ $OTROS_ESCRIBIR == true ]]; then
			
			TECLADO=""
			CONTINUAR=true
			while [[ $CONTINUAR == true ]]; do
				
				echo -e "\n--------------------------------------"
				echo -e "Se encontraron archivos que permiten que «otros» escriban en ellos"
				echo -e "¿Quiere verlos\? (S/n)"
				read TECLADO

				if [[ $TECLADO == "" ]]; then
					TECLADO="S"
				fi

				case $TECLADO in
					S|s)
						echo "$LISTA_OTROS_ESCRITURA" | less
						CONTINUAR=false
						;;
					N|n)
						CONTINUAR=false
						;;
					* )
						echo Respuesta incorrecta
						;;
				esac
			done

			TECLADO=""
			CONTINUAR=true
			while [[ $CONTINUAR == true ]]; do
				
				echo -e "\n--------------------------------------"
				echo -e "¿Quiere quiere quitar los permisos de escritura a «otros» de esos archivos\? (S/n)"
				read TECLADO

				if [[ $TECLADO == "" ]]; then
					TECLADO="S"
				fi

				case $TECLADO in
					S|s)
						CONTINUAR=false
						;;
					N|n)
						#vaciar la lista de archivos
						LISTA_OTROS_ESCRITURA_SIMPLE=""
						CONTINUAR=false
						;;
					* )
						echo Respuesta incorrecta
						;;
				esac
			done
			quiere_continuar
		fi
	fi

	if [[ $PROBLEMAS == true ]]; then
		reempaquetar "$ARCHIVO" "$LISTA_OTROS_ESCRITURA_SIMPLE"
	else
		echo No se encontraron problemas de permisos
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

case $# in
	0 )
		echo No se encontraron parápetros, especifique un archivo .deb o una carpeta
		exit 0
		;;
	1 )
		UBICACION=$1
		;;
	2 )
		PARAMEPTRO=$1
		UBICACION=$2

		case $PARAMEPTRO in
			-i )
				MODO_INTERACTIVO=true
				;;
			* )
				echo El parápetro «$PARAMEPTRO» no es valido.
				exit 1
				;;
		esac
		;;
	* )
		echo Especifique solo un archivo a la vez
		exit 1
		;;
esac

if [[ -f "$UBICACION" ]]; then

	#si no es un archivo .deb
	analizar_deb "$UBICACION"
elif [[ -d "$UBICACION" ]]; then
	
	buscar_deb "$UBICACION"
else
	echo $i no existe.
fi
