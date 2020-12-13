#! /bin/bash

PARAMEPTRO=""
ARCHIVO=""
MODO_INTERACTIVO=false

#echo $#

case $# in
	1 )
		ARCHIVO=$1
		;;
	2 )
		PARAMEPTRO=$1
		ARCHIVO=$2

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


#echo PARAMEPTRO: $PARAMEPTRO
#echo ARCHIVO: $ARCHIVO

reempaquetar () {
	echo reempaquetando $ARCHIVO
}

# Si no tiene parápetros
if [[ -z $ARCHIVO ]]; then

	echo No se encontraron parápetros. Especifique un archivo .deb
	exit 0
fi

#si no es un archivo .deb
if [[ $(echo $ARCHIVO | grep -Ev ".deb$") ]]; then
	
	echo El archivo $ARCHIVO no es un .deb
	exit 1
fi

#verificar que el archivo existe
if [[ -f $ARCHIVO ]]; then

	echo Analizando $ARCHIVO

	LISTA=$(dpkg-deb --contents $ARCHIVO)
	LISTA_NO_ROOT=$(echo "$LISTA" | grep -Ev " root/root ")
	LISTA_HOME=$(echo "$LISTA" | grep -E " ./home/")

	if [[ $LISTA_HOME ]]; then
		echo -e "\n--------------------------------------"
		echo "$LISTA_HOME"
		echo Advertencia: se extraen $(echo "$LISTA_HOME" | wc -l) archivos o carpetas dentro de /home.
	fi

	echo -e "\n--------------------------------------"
	if [[ $LISTA_NO_ROOT ]]; then

		echo "$LISTA_NO_ROOT"
		echo $(echo "$LISTA_NO_ROOT" | wc -l) archivos o carpetas no tienen como propietario y grupo a «root»

		if [[ $MODO_INTERACTIVO == true ]]; then
			
			TECLADO=""
			CONTINUAR=true
			while [[ $CONTINUAR == true ]]; do
				
				echo -e "\n¿Quiere reempaquetar a $ARCHIVO y asignar como propietario a root a todos los archivos\? (S/n)"
				read TECLADO

				if [[ $TECLADO == "" ]]; then
					TECLADO="S"
				fi

				#echo TECLADO: $TECLADO

				case $TECLADO in
					S|s)
						reempaquetar
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
		else
			reempaquetar
		fi
	else
		echo No se encontraron errores de propietario o grupo en los archivos
	fi

	echo -e "\n--------------------------------------"
	LISTA_OTROS_ESCRITURA=$(echo "$LISTA" | grep -E "^(d|-).......w. " )
	if [[ $LISTA_OTROS_ESCRITURA ]]; then
		
		echo Los siguientes archivos o carpetas pueden ser ecritos por cualquiera
		echo "$LISTA_OTROS_ESCRITURA"
	else
		echo No se encontraron errores en los que cualquiera puede escribir en los archivos o carpetas
	fi

else
	echo El archivo $ARCHIVO no existe
	exit 1
fi

exit 0
