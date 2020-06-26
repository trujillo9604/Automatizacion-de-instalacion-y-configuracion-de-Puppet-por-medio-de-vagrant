# Instalacion-y-configuracion-de-Puppet-por-medio-de-Vagrant

El procedimiento a realizar esta dado por el despliegue y configuracion de Puppet. Posteriormente se anexan los manifest, files y script que permiten el despliegue y configuración de HTCondor a través de Puppet. 

El entorno en el que se desarrolla este proyecto esta dado por 3 maquinas virtuales, generadas con Vagrant (herramienta para la creación y configuración de entornos de desarrollo virtualizados). Se tendran dos arquitecturas desplegadas con la ayuda de Vagrant, el cual sera master-agent, perteneciente al gestor de configuracion Puppet y al finalizar el despliegue y configuracion de Puppet, se tendra una arquitectura perteneciente a HTCondor (master-worker), la cual nos la facilitara el gestor de configuracion Puppet. Estas tres maquinas virtuales tendran como nombre: 

puppet, quien sera el Puppet master de este entorno, 

puppetagent1 y puppetagent2, quienes seran las maquinas que se encargaran de ser dotadas de un gestor de cola de tareas, a traves de Puppet y a su ves seran                  clientes puppet.

Gracias al archivo Vagrantfile que se anexa en este repositorio, se permite agilizar la instalacion y configuracion del gestor de configuraciones Puppet, entregando como resultado una maquina con rol master y 2 maquinas como clientes, debidamente configuradas por el archivo Vagrantfile y certificadas por el puppet master para su posterior uso.
El Puppet master debe aprobar una solicitud de certificado para cada nodo agente antes de poder configurarlo. Este proceso se encuentra automatizado dentro del archivo Vagrantfile.  El despliegue de HTCondor estara dado posteriormente a la creacion de las maquinas virtuales. Puppet sera el encargado de gestar la configuracion de HTCondor en 2 de los 3 nodos creados con anterioridad. Esto se explicara en el transcurso del readme.

Las recomendaciones a tener en cuenta para que este entorno funcione conrrectamente y Puppet no presente problema alguno, es el siguiente.

* Se anota que la maquina puppet master tendra el nombre de puppet y los nodos clientes tendran el nombre de puppetagent1 y puppetagent2.  
* Verificar y corregir las ubicaciones de cada proceso de aprovisionamiento (script, sincronizacion de carpeta compartida) en el archivo Vagrantfile.
* La ejecucion de cualquier comando para el trabajo o configuracion de puppet en las maquinas virtuales debe ser efectuado con usuario root. 
* Teniendo en cuenta la recomendacion anterior, se anota que para establecer un password para el usuario root basta con digitar el comando (sudo passwd                         root).
* La maquina que sera puppet master debera tener como minimo 3 gigas de Ram, debido a que en la inicializacion del proceso (puppetserver.service) en su archivo de               configuracion viene por defecto para uso de 2 gigas de ram despues de su instalacion. Esto se puede modificar en su propio archivo de configuracion ubicado en                 /etc/puppetlabs/puppet/puppet.conf. Puppet Server es el software que se instala una unica ves en el puppet master y es el encargado de hacer cumplir el rol de                 nodo master.  Para uso de este despliegue se han otorgado estas 3 gigas de Ram a la maquina virtual puppet master y asi evitar problemas en el despliegue.
        
A continuacion se muestra el archivo Vagrantfile, exponiendo los scripts utilizados y el aprovisionamiento para cada maquina desarrollado.

# Instalacion de puppet-server y puppet-agent en nodo puppet master 

El box utilizado para las 3 maquinas virtuales sera /ubuntu/xenial64.

Script para el despliegue de puppetserver en la maquina master llamada "puppet" 

Se actualiza los repositorios de la maquina.        

        sudo apt-get -y update
        sudo apt-get -y upgrade    

Sincronizar zona horaria en cada nodo del cluster. Si surge un problema de sincronizacion de tiempo, los certificados podran aparecer vencidos, existiendo discrepancias entre  el Puppet master y los Puppet agent nodes. 

        sudo timedatectl set-timezone "America/Bogota"
        sudo hostnamectl set-hostname puppet               

Instalacion de puppetserver y puppetagent en la maquina master

Agregamos los repositorios de Puppet desde el sitio oficial de Puppet, actualizamos los repositorios de nuestro box y posteriormente ejecutamos su instalacion.

        sudo wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
        sudo dpkg -i puppetlabs-release-pc1-xenial.deb
        sudo apt-get -y update
        sudo apt-get -y install puppet-agent
        sudo apt-get -y install puppetserver

Nos asegurarnos de que el puppetserver.service y el firewall permitan que el proceso JVM de Puppet Server acepte conexiones en el puerto 8140. Además, los clientes puppet deben poder realizar la conexión al maestro en ese mismo puerto. Esta configuracion es predeterminada para esta herramienta.

        sudo ufw allow 8140   

Finalizada la instalacion iniciamos el servicio de puppetserver.service y dejamos habilitado el servicio, para cada momento que la maquina inice. Es de considerar que esta maquina es la encargada de administrar los clientes puppet y velara  por la configuracion establecida para cada uno.

        sudo systemctl  start   puppetserver.service
        sudo systemctl  enable  puppetserver.service

# Firmar certificados de los clientes puppet

En este desarrollo, las maquinas tienen un orden para crearse con Vagrant. Es decir, inicialmente se deben crear las maquinas clientes puppet (puppetagent1 y                 puppetagent2) y por ultimo el puppet master. Esto es debido a que el servicio puppetserver.service debe recibir un certificado SSL por parte de cada cliente puppet y         posteriormente ser validadas (firmadas) por el puppetserver. Si creamos primero la maquina puppet master y luego los clientes puppet, indicara que primero se iniciara el      servicio puppetser.service y hasta ese momento no existira ningun agente creado para certificar. En el momento que los agentes son creados, las maquinas pueden ser           firmadas por el nodo puppet master, pero se debera reiniciar el servicio puppetserver.service. Con este orden de creacion nos evitamos ese paso y tendremos un despliegue     mucho mas automatizado con Vagrant.

# Instalacion de puppet-agent en los nodos clientes puppet

Actualizacion del box y sincronizacion de zona horaria

        sudo apt-get -y update
        sudo apt-get -y upgrade    
        sudo timedatectl set-timezone "America/Bogota"
        

Instalacion de puppetagent

        sudo wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
        sudo dpkg -i puppetlabs-release-pc1-xenial.deb
        sudo apt-get -y update
        sudo apt-get -y install puppet-agent


Activacion de servicios puppet, con el fin de que cada cliente puppet logre generar una conexion con el puppet master.

        sudo systemctl start    puppet.service
        sudo systemctl enable   puppet.service

SCRIPT

# Creacion y configuracion de las maquinas virtuales.

En el proceso anterior se muestras los scripts para dotar las maquinas con los softwares necesarios. A continuacion se muestra la configuracion de cada maquina virtual creada:

Como se menciono anteriormente, inicialemente se crea las maquina clientes puppet y luego el puppet master.

Nodo cliente puppet 1 

        Vagrant.configure('2') do |config|
        config.vm.define "puppetagent1" do |puppetagent1|
  
        #Box a utilizar, previamente descargado
        puppetagent1.vm.box = 'ubuntu/xenial64'

Hostname
        
        puppetagent1.vm.hostname = "puppetagent1"

IP privada
        
        puppetagent1.vm.network 'private_network', ip: '192.168.20.19'

* Aprovisionamiento de maquina 

        puppetagent1.vm.provision "shell", inline: "sudo hostnamectl set-hostname puppetagent1"
        puppetagent1.vm.provision "shell", inline:  $script2, privileged: true, reset: true

* Modificar archivo hosts

Este archivo ubicado en /etc/hosts permite apuntar un nombre de dominio de nuestra elección a un servidor en concreto, a un ordenador en red local o a nuestra misma máquina a través de su IP, alias o dominio. Este archivo se modifica por medio del script "hosts.sh" el cual permite reemplazar el archivo propio de la maquina virtual creada, con un archivo hosts creado por nosotros, con la informacion de red de cada nodo. Debido a que trabajamos en un entorno virtual, tuvimos que apoyarnos en el recurso file de Vagrant, con el proposito de sincronizar la carpeta en donde se aloja nuestro archivo hosts y posteriormente poder reemplazarlo.

        puppetagent1.vm.provision "file", source: "/home/fabian/Documentos/segunda_prueba", destination: "$HOME/archivos"        
        puppetagent1.vm.provision "shell", path: "añadir_hostname.sh", privileged: true

* Revelar quien es su master        

Es muy importante anotar en este punto, que dad la arquitectura que maneja Puppet con relacion a master-agent, cada agente puppet debe conocer de antemano quien su master y esta configuracion se automatiza por medio del script "Puppet.conf_agentes.sh", el cual escribe en el archivo de configuracion de Puppet agent, instalado previamente en la maquina cliente y añade la linea de quien es su server. Este proceso queda automatizado por medio del script.

        puppetagent1.vm.provision "shell", path: "Puppet.conf_agentes.sh", privileged: true    
            
    end 


* Nodo de trabajo2

        config.vm.define "puppetagent2" do |puppetagent2|
  
* Box a utilizar, previamente descargado

        puppetagent2.vm.box = 'ubuntu/xenial64'

* Hostname

        puppetagent2.vm.hostname = "puppetagent2"

* IP privada

        puppetagent2.vm.network 'private_network', ip: '192.168.20.20'

* Aprovisionamiento de maquina 

        puppetagent2.vm.provision "shell", inline: "sudo hostnamectl set-hostname puppetagent2"
        puppetagent2.vm.provision "shell", inline:  $script2, privileged: true, reset: true
        puppetagent2.vm.provision "file", source: "/home/fabian/Documentos/segunda_prueba", destination: "$HOME/archivos"        
        puppetagent2.vm.provision "shell", path: "añadir_hostname.sh", privileged: true
        puppetagent2.vm.provision "shell", path: "Puppet.conf_agentes.sh", privileged: true    
            
    end 

* Maquina puppet master

        config.vm.define "puppet" do |puppet|
    
* Box a utilizar, previamente descargado
       
       puppet.vm.box = 'ubuntu/xenial64'
* Hostname
       
       puppet.vm.hostname = "puppet"

+ IP privada
        
        puppet.vm.network 'private_network', ip: '192.168.20.18'


* Aprovisionamiento de maquina 
        
        puppet.vm.provision "shell", inline:  $script, privileged: true, reset: true
        puppet.vm.provision "file",  source:  "/home/fabian/Documentos/segunda_prueba", destination: "$HOME/archivos"        
        puppet.vm.provision "shell", path:    "añadir_hostname.sh", privileged: true
        puppet.vm.provision "shell", path:    "certificar_nodos.sh", privileged: true
        
        

* Personalizar maquina virtual    
        
        puppet.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", 3072]   

          end 
        end
      end


# Despliegue de HTCondor por medio de Puppet.

Finalizado el despliegue de Puppet en las 3 maquinas virtuales y posterior a esto, cada nodo con rol cliente puppet siendo certificado, se procede a desplegar el gestor de cola de tareas. Para esta operacion se anexan los manifest encargados de la configuracion de cada nodo cliente puppet. Es decir, cada manifest tendra el estado deseado para cada nodo cliente, y el puppet master se encargara de efectuar  y supervisar correctamente su configuracion. 

Los archivos manifest de Puppet son los archivos donde se declaran todos los recursos, es decir, servicios, paquetes o archivos que deben verificarse y cambiarse. Los archivos manifest de Puppet se crean en Puppet master y tienen la extensión .pp. Estos archivos son compuestos por las siguientes carpetas. 

 * Files: Son los archivos de texto sin formato que se deben importar y colocar en la ubicación de destino. 
 * Resources: Los recursos representan los elementos que necesitamos evaluar o cambiar. Los recursos pueden ser archivos, paquetes, etc. 
 * Node definition: Es un bloque de código en Puppet donde se define toda la información y definición del nodo del cliente. 
 * Templates: Los templates se utilizan para crear archivos de configuración en los nodos y se pueden reutilizar más tarde. 
 * Classes: Las classes son lo que utilizamos para agrupar los diferentes tipos de recursos.
        
Teniendo en cuenta lo anterior se exponen las recomendaciones para que el manifest de HTCondor sea tomado correctamente por puppet.

Pasos en la maquina puppet master

* Se guardan los manifest subido al repositorio en la carpeta manifest de puppetserver. Esta carpeta se encuentra ubicada en                                                     /etc/puppetlabs/puppet/code/environment/production/manifest.
* La carpeta modules subido al repositorio, sera reemplazada con el modules de puppet server en la ubicacion /etc/puppetlabs/puppet/code/environment/production/modules.         Esta carpeta contiene los files necesarios para configurar el entorno de HTCondor.
        
#Pasos en los clientes Puppet

Teniendo ya los manifest y files necesarios alojados en el servidor master de puppet, se procede a pedir la configuracion por parte de cada nodo cliente al puppet             master. Para que este proceso se concluya de manera satisfactoria se debe habe realizado paso a paso las instrucciones dictadas, en las que incluyen, modificar las            ubicaciones de las carpetas, scripts y lo mas importante, tener el cliente verificado y certificado por el puppet server. El comando a correr es el siguiente.
        
        /opt/puppetlabs/puppet/bin/puppet agent -t 
       
Inmediatamente el cliente puppet realizara una peticion a traves del puerto 8140 al puppet server y el puppet server, en funcion del manifest añadido en sus carpetas,        procedera a realizar el despliegue de configuracion para dicho nodo. Esto aplica para todo los dos nodos de este entorno, obteniendo como resultado el despliegue y           configuracion del pool de HTCondor en los dos nodos clientes puppet. El nodo puppetagent1 actuara como el master de HTCondor y el puppetagent2 sera un worker del pool de      HTCondor. 
        
        
        
        








