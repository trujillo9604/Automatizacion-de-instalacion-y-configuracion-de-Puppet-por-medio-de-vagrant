# Automatizacion-de-la-instalacion-y-configuracion-de-Puppet-por-medio-de-Vagrant

El procedimiento a realizar estara dado por el despliegue y configuracion de Puppet master quien actuara como el servidor que tendra las configuraciones para los clientes o tambien llamados, Puppet agent nodes. Posteriormente se anexan los manifest, files y script que permiten el despliegue y configuración de HTCondor a través de Puppet. 

El entorno en el que se desarrollo este proyecto esta dado por 3 maquinas virtuales, generadas con Vagrant (herramienta para la creación y configuración de entornos de desarrollo virtualizados). Se tendran dos escenarios cliente-servidor al finalizar el despliegue del gestor de configuracion (Puppet) y el gestor de cola de tareas (HTCondor). 

Gracias al archivo Vagrantfile que se anexa en este repositorio, se permitira agilizar la instalacion y configuracion de Puppet, entregando como resultado una maquina con rol de Puppet master y 2 maquinas como clientes puppet, debidamente configuradas y certificadas por el Puppet master. El Puppet master debe aprobar una solicitud de certificado para cada nodo de agente antes de poder configurarlo. Este proceso se encuentra automatizado dentro del archivo Vagrantfile.  El despliegue de HTCondor estara dado posteriormente a la creacion de las maquinas virtuales. Puppet sera el encargado de gestar la configuracion de HTCondor en 2 de los 3 nodos creados con aterioridad. Esto se explicara en el transcurso del readme.

Las recomendaciones a tener en cuenta para que este entorno funcione conrrectamente y Puppet no presente problema alguno, es el siguiente.

        1- Verificar y corregir las ubicaciones de cada proceso de aprovisionamiento (script, sincronizacion de carpeta compartida) en el archivo Vagrantfile.
        2- La ejecucion de cualquier comando para el trabajo o configuracion de puppet en las maquinas virtuales debe ser efectuado con usuario root. 
        3- La maquina que sera puppet master debera tener como minimo 3 gigas de Ram, debido a que en la inicializacion del proceso (puppetserver) por parte del              archivo Vagrantfile, por defecto viene configurada para uso de 2 gigas de ram. Esto se puede modificar en el archivo de configuracion de puppet                    ubicado en /etc/puppetlabs/puppet/puppet.conf. Para uso de este despliegue se han otorgado estas 3 gigas a la maquina virtual puppet master y asi                  evitar problemas en el despliegue.
        4- Teniendo en cuenta la recomendacion anterior, se anota que para establecer un password para el usuario root basta con digitar el comando (sudo passwd              root).
        
A continuacion se muestra el archivo Vagrantfile, exponiendo los scripts utilizados y el aprovisionamiento para cada maquina desarrollado.

# Instalacion de Puppet-server y Puppet agent nodes en 

El box utilizado para las 3 maquinas virtuales sera /ubuntu/xenial64.

#Script para el despliegue de puppetserver en la maquina master llamada "puppet" 

Se actualiza los repositorios de la maquina.        
sudo apt-get -y update
sudo apt-get -y upgrade    


sudo timedatectl set-timezone "America/Bogota"
sudo hostnamectl set-hostname puppet               

#Instalacion de puppetserver y puppetagent
Descargamos el paquete, lo descomprimimos y posteriormente ejecutamos su instalacion.

sudo wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
sudo dpkg -i puppetlabs-release-pc1-xenial.deb
sudo apt-get -y update
sudo apt-get -y install puppet-agent
sudo apt-get -y install puppetserver

Nos asegurarnos de que el Puppetserver permita y pueda manejar las conexiones entrantes en el puerto 8140. Además, los nodos del agente deben poder realizar la conexión al maestro en ese mismo puerto. Esta configuracion es predeterminada para esta herramienta.
sudo ufw allow 8140   

#Finalizada la instalacion iniciamos el servicio de puppet server y dejamos que quede habilitado, así la maquina se reinicie. Es de considerar que esta maquina
#es la encargada de administrar los agent puppet nodes y velara por la configuracion establecida para cada uno.

sudo systemctl  start   puppetserver.service
sudo systemctl  enable  puppetserver.service

#Firmar certificados de los nodos agentes Puppet

En este desarrollo, las maquina tienen un orden para crearse con Vagrant. Es decir, inicialmente se deben crear las maquinas clientes puppet (agent nodes Puppet) y por ultimo el puppet master. Esto es debido a que el servicio puppetserver.service debe recibir un certificado SSL por parte de cada nodo agente y posteriormente ser validadas (firmadas) por el puppetserver. Si creamos primero la maquina puppet master y luego los agentes puppet, indicara que primero se iniciara el servicio puppetser.service y hasta ese momento no existira ningun agente para certificar. En el momento que los agentes son creados, las maquinas pueden ser firmadas por el nodo puppet master, pero se debera reiniciar el servicio puppetserver.service. Con este orden de creacion nos evitamos ese paso y 
tendremos un despliegue mucho mas automatizado con Vagrant.

#Actualizacion del box y instalacion de puppetagent

sudo apt-get -y update
sudo apt-get -y upgrade    
sudo timedatectl set-timezone "America/Bogota"
        

#Instalacion de puppetserver y puppetagent

sudo wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
sudo dpkg -i puppetlabs-release-pc1-xenial.deb
sudo apt-get -y update
sudo apt-get -y install puppet-agent


# Activacion de servicios

sudo systemctl start     puppet.service
sudo systemctl enable    puppet.service

SCRIPT


#Nodo de trabajo 1 

Vagrant.configure('2') do |config|
         config.vm.define "puppetagent1" do |puppetagent1|
  
# Box a utilizar, previamente descargado
        
        puppetagent1.vm.box = 'ubuntu/xenial64'

#Hostname

        puppetagent1.vm.hostname = "puppetagent1"

#IP privada

        puppetagent1.vm.network 'private_network', ip: '192.168.20.19'

#Aprovisionamiento de maquina 

        puppetagent1.vm.provision "shell", inline: "sudo hostnamectl set-hostname puppetagent1"
        puppetagent1.vm.provision "shell", inline:  $script2, privileged: true, reset: true
        puppetagent1.vm.provision "file", source: "/home/fabian/Documentos/segunda_prueba", destination: "$HOME/archivos"        
        puppetagent1.vm.provision "shell", path: "añadir_hostname.sh", privileged: true
        puppetagent1.vm.provision "shell", path: "Puppet.conf_agentes.sh", privileged: true    
            
    end 


#Nodo de trabajo2

        config.vm.define "puppetagent2" do |puppetagent2|
  
# Box a utilizar, previamente descargado

        puppetagent2.vm.box = 'ubuntu/xenial64'

#Hostname

        puppetagent2.vm.hostname = "puppetagent2"

#IP privada

        puppetagent2.vm.network 'private_network', ip: '192.168.20.20'

#Aprovisionamiento de maquina 

        puppetagent2.vm.provision "shell", inline: "sudo hostnamectl set-hostname puppetagent2"
        puppetagent2.vm.provision "shell", inline:  $script2, privileged: true, reset: true
        puppetagent2.vm.provision "file", source: "/home/fabian/Documentos/segunda_prueba", destination: "$HOME/archivos"        
        puppetagent2.vm.provision "shell", path: "añadir_hostname.sh", privileged: true
        puppetagent2.vm.provision "shell", path: "Puppet.conf_agentes.sh", privileged: true    
            
    end 


#Maquina puppet master

    config.vm.define "puppet" do |puppet|
    
# Box a utilizar, previamente descargado
        puppet.vm.box = 'ubuntu/xenial64'

#Hostname
        puppet.vm.hostname = "puppet"

#IP privada
        puppet.vm.network 'private_network', ip: '192.168.20.18'


#Aprovisionamiento de maquina 
        
        puppet.vm.provision "shell", inline:  $script, privileged: true, reset: true
        puppet.vm.provision "file",  source:  "/home/fabian/Documentos/segunda_prueba", destination: "$HOME/archivos"        
        puppet.vm.provision "shell", path:    "añadir_hostname.sh", privileged: true
        puppet.vm.provision "shell", path:    "certificar_nodos.sh", privileged: true
        
        

#Personalizar maquina virtual    
        puppet.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", 3072]   

        end 
    end

end







