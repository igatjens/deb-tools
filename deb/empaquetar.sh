#!/bin/bash


NOMBRE_PAQUETE=deb-tools
VERSION_PAQUETE=1.1-0
ARQUITECTURA_PAQUETE=amd64

CARPETA_DE_TRABAJO=$NOMBRE_PAQUETE"_"$VERSION_PAQUETE"_"$ARQUITECTURA_PAQUETE

echo Nombre: $NOMBRE_PAQUETE
echo Versión: $VERSION_PAQUETE
echo Arquitectura: $ARQUITECTURA_PAQUETE
echo Nombre del paquete .deb: $CARPETA_DE_TRABAJO
echo ""

# Crear carpeta si no exite
mkdir -p "$CARPETA_DE_TRABAJO"
mkdir -p "$CARPETA_DE_TRABAJO/DEBIAN"

#echo Habilitar perimos de edición
#sudo chown -R $(whoami):$(whoami) $CARPETA_DE_TRABAJO/*

echo Actualizando archivos

cp -uv ../deb-buscar-problemas-permisos.sh "$CARPETA_DE_TRABAJO"/usr/bin/deb-buscar-problemas-permisos
cp -uv ../deb-corregir-nombre-archivo.sh "$CARPETA_DE_TRABAJO"/usr/bin/deb-corregir-nombre-archivo
cp -uv ../deb-reparar-permisos.sh "$CARPETA_DE_TRABAJO"/usr/bin/deb-reparar-permisos



echo Actualizar registro de cambios
RESPUESTA=""

echo "Abortar = Ctrl+C"
read $RESPUESTA


# Anotar registro de cambios
mkdir -p "$CARPETA_DE_TRABAJO/usr/share/doc/$NOMBRE_PAQUETE/"
gunzip $CARPETA_DE_TRABAJO/usr/share/doc/$NOMBRE_PAQUETE/changelog.gz
dedit $CARPETA_DE_TRABAJO/usr/share/doc/$NOMBRE_PAQUETE/changelog
gzip -9 $CARPETA_DE_TRABAJO/usr/share/doc/$NOMBRE_PAQUETE/changelog


#echo Eliminar espacios de los nombres de los archivos
#RESPUESTA=""

#echo "Abortar = Ctrl+C"
#read $RESPUESTA


# Suma de verificación
#/deb/$CARPETA_DE_TRABAJO/DEBIAN/md5sums

# Eliminar espacios de los nombres de los archivos
#./elininar-espacios-nombres.sh



echo Crear md5sums
RESPUESTA=""

echo "Abortar = Ctrl+C"
read $RESPUESTA



# limpiar archivo

cd $CARPETA_DE_TRABAJO

cat /dev/null > DEBIAN/md5sums


LISTA=$(ls)

for i in $LISTA; do

	# Si no es de la carpeta ./DEBIAN
	if [[ $(echo $i | grep -v -E "^DEBIAN") ]]; then
		echo $i
		find $i -type f -name  "*" -exec md5sum {} \; >> DEBIAN/md5sums
	fi
done


cd ..



cd $CARPETA_DE_TRABAJO

SIZE_INSTALADO=$( expr $(du --max-depth=1 | grep -E "(DEBIAN|\.$)" | sed "s|$| |; s|\t| |g" | tr -d "\n" | tr -s [:blank:] | cut -d " " -f1,3 | sed "s|^|-|; s| | + |") )

echo Tamaño instalado: $SIZE_INSTALADO

cd ..



echo Revisar scripts del .deb
RESPUESTA=""

echo "Abortar = Ctrl+C"
read $RESPUESTA


#Actualizar preinst postinst etc
#/deb/$CARPETA_DE_TRABAJO/DEBIAN/
dde-file-manager $CARPETA_DE_TRABAJO/DEBIAN/


echo Editar control
RESPUESTA=""

echo "Abortar = Ctrl+C"
read $RESPUESTA


#Actualizar control
#/deb/$CARPETA_DE_TRABAJO/DEBIAN/control
dedit $CARPETA_DE_TRABAJO/DEBIAN/control


echo Generar paquete
RESPUESTA=""

echo "Abortar = Ctrl+C"
read $RESPUESTA

fakeroot sh -c \
"chown -R root:root $CARPETA_DE_TRABAJO/*;\
dpkg-deb --build $CARPETA_DE_TRABAJO;"