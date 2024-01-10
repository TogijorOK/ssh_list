#!/bin/bash

if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then   errx \     "Requires bash greater-than or equal to four (${BASH_VERSINFO[0]}>=4)." \     99 \   ;
fi

hosts_file="hosts.txt"  # Nombre del archivo para almacenar los hosts

# Colores y formato
cyan='\033[0;36m'
yellow='\033[1;33m'
red='\033[0;31m'
nc='\033[0m' # Sin color
bold=$(tput bold)
normal=$(tput sgr0)

# Verificar si el archivo existe; si no, crearlo
if [ ! -e "$hosts_file" ]; then
    touch "$hosts_file"
fi

# Función para cargar los hosts desde el archivo
function cargar_hosts() {
    mapfile -t hosts < "$hosts_file"
}

# Función para guardar los hosts en el archivo
function guardar_hosts() {
    printf "%s\n" "${hosts[@]}" > "$hosts_file"
}

# Función para mostrar las opciones disponibles
function mostrar_opciones() {
    echo -e "${yellow}${bold}Opciones disponibles:${nc}"
    echo -e "${cyan}+${nc} ${bold}add host${normal}"  # Opción para agregar un host
    echo -e "${red}-${nc} ${bold}delete host${normal}"  # Opción para eliminar un host
    for ((i=0; i<${#hosts[@]}; i++)); do
        echo -e "${cyan}$((i+1)).${nc} ${hosts[$i]}"
    done
}

# Función para agregar un nuevo host a la lista
function agregar_host() {
    echo
    read -p "$(echo -e ${yellow}${bold}"Ingresa el nuevo host (Enter para finalizar / ESC para cancelar):"${nc})"$'\n' nuevo_host
    if [[ $nuevo_host == $'\e' ]]; then
        echo -e "${red}Operación cancelada.${nc}"
        return 1
    elif [[ -z "$nuevo_host" ]]; then
        echo -e "${red}Nombre de host vacío. Operación cancelada.${nc}"
        return 1
    fi
    hosts+=("$nuevo_host")
    guardar_hosts  # Guardar la lista actualizada en el archivo
    echo -e "${cyan}Host '$nuevo_host' agregado.${nc}"
}

# Función para eliminar un host de la lista
function eliminar_host() {
    mostrar_opciones
    read -rp "$(echo -e ${yellow}${bold}"Selecciona el número del host a eliminar (Enter para borrar / ESC para cancelar):"${nc}) " opcion_eliminar
    if [[ $opcion_eliminar == $'\e' ]]; then
        echo -e "${red}Operación cancelada.${nc}"
        return 1
    elif [[ $opcion_eliminar == "" ]]; then
        echo -e "${red}No se seleccionó ningún host para eliminar.${nc}"
        return 1
    elif [[ "$opcion_eliminar" == "+" ]]; then
        agregar_host
        return $?
    elif [[ $opcion_eliminar =~ ^[0-9]+$ && $opcion_eliminar -le ${#hosts[@]} ]]; then
        index=$(($opcion_eliminar - 1))
        host_eliminado="${hosts[$index]}"
        unset 'hosts[$index]'
        hosts=("${hosts[@]}")
        guardar_hosts

        if [ ${#hosts[@]} -eq 0 ]; then
            > "$hosts_file"  # Si no hay hosts, se vacía el archivo
        fi

        echo -e "${cyan}Host '$host_eliminado' eliminado.${nc}"
    else
        echo -e "${red}Opción no válida.${nc}"
    fi
}

# Bucle principal
while true; do
    cargar_hosts

    mostrar_opciones

    # Pedir al usuario que elija una opción
    read -rsn1 -p "$(echo -e ${yellow}${bold}"Selecciona una opción (+/-/1-$(( ${#hosts[@]} ))):"${nc}) " opcion

    # Verificar la opción seleccionada
    if [[ "$opcion" == "+" ]]; then
        agregar_host
    elif [[ "$opcion" == "-" ]]; then
        eliminar_host
    elif [[ $opcion -gt 0 && $opcion -le ${#hosts[@]} ]]; then
        host_elegido="${hosts[$opcion - 1]}"
        echo
        read -p "Conectándose a $host_elegido. Usuario: " usuario
        ssh $usuario@$host_elegido
    else
        echo -e "${red}Opción no válida.${nc}"
    fi
done

while true; do
    cargar_hosts

    mostrar_opciones

    # Pedir al usuario que elija una opción
    read -rsn1 -p "$(echo -e ${yellow}${bold}"Selecciona una opción (+/-/1-$(( ${#hosts[@]} ))):"${nc}) " opcion

    # Verificar la opción seleccionada
    if [[ "$opcion" == "+" ]]; then
        agregar_host
    elif [[ "$opcion" == "-" ]]; then
        eliminar_host
    elif [[ $opcion -gt 0 && $opcion -le ${#hosts[@]} ]]; then
        host_elegido="${hosts[$opcion - 1]}"
        read -p "Conectándose a $host_elegido. Usuario: " usuario
        ssh $usuario@$host_elegido
    else
        echo -e "${red}Opción no válida.${nc}"
    fi
done
