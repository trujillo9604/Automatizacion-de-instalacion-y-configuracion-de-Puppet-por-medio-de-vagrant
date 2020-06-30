#!/bin/bash 

sudo cp  -r /vagrant/hosts /etc/hosts 

#Modificar archivo hosts 
numero="127.0.0.1 "
nombre=$(hostname)

linea=$numero$nombre

echo "$linea">> /etc/hosts

