# Automatizacion-de-instalacion-y-configuracion-de-Puppet-por-medio-de-vagrant

Se despliega y configura Puppetmaster y Puppet agent nodes,  por medio de Vagrant. Posteriormente se anexan los manifest, files y script que permiten el despliegue y configuración de HTCondor a través de Puppet. 

El entorno en el que se ejecuta este proyecto esta dado por 3 maquinas virtuales, generadas con Vagrant (herramienta para la creación y configuración de entornos de desarrollo virtualizados). Se tendran dos escenarios cliente-servidor al finalizar el despliegue del gestor de cossh nfiguracion (Puppet) y el gestor de cola de tareas (HTCondor) 

Gracias al archivo Vagrantfile que se anexa en este repositorio, permitira agilizar la instalacion y configuracion de Puppet, entregando como resultado una maquina con rol de puppet master y 2 maquinas como clientes puppet o agentes. El archvio Vagrant file dotara estas 3 maquinas hasta el punto de certificarlas. El despliegue de HTCondor por medio de puppet se explicara en el transcurso del readme.

Instalacion de Puppet-server y Puppet agent nodes en /ubuntu/xenial64.

        Script para el despliegue de puppetserver en la maquina master llamada "puppet" 

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







