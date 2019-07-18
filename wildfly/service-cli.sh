#!/bin/bash

export ID=50
export SERVICE=wildfly

function ascii {
    echo -e ""
    echo -e " WELCOME TO "
    echo -e ""	
    echo -e "   __          _______ _      _____  ______ _  __     __   "
    echo -e "   \ \        / /_   _| |    |  __ \|  ____| | \ \   / /   "
    echo -e "    \ \  /\  / /  | | | |    | |  | | |__  | |  \ \_/ /    "
    echo -e "     \ \/  \/ /   | | | |    | |  | |  __| | |   \   /     "
    echo -e "      \  /\  /   _| |_| |____| |__| | |    | |____| |      "
    echo -e "       \/  \/   |_____|______|_____/|_|    |______|_|      "
    sleep 2
}

function usage {
    echo -e "#########################################################################################################################################"
    echo -e "  Utilizzo:"
    echo -e "             ./service-cli.sh start|start-int|stop|restart|deploy|test|build                                                           "
    echo -e "                              [-d|--debug] [-U|--update] [-t=<DOCKER_TAG>|--tag=<DOCKER_TAG>]                                          "
    echo -e "                              [-m=<TYPE>|--mode=<TYPE>] [-S|--sonar]                                                                      "
    echo -e ""
    echo -e "  Esempi:"
    echo -e "             ./service-cli.sh start -d"
    echo -e ""
    echo -e "                 -> Effettua lo start del servizio avviando JBoss in Debug Mode"
    echo -e ""
    echo -e "             ./service-cli.sh stop"
    echo -e "                                                                                                                                                 "
    echo -e "                 -> Effettua lo stop del servizio"
    echo -e ""    
    echo -e "                    Porte:"
    echo -e ""
    echo -e "                         80$ID  ->  JBoss Http"
    echo -e "                         99$ID  ->  JBoss Management"
    echo -e "                         87$ID  ->  JBoss Debug"
    echo -e "#########################################################################################################################################"
}

function print_env {
	
	echo -e "#######################################################################"
	echo -e "  SERVICE:    ${bcyan}$SERVICE${nc}"
	echo -e "  STANDALONE: ${bcyan}$STANDALONE${nc}"
	echo -e "  ID:         ${bcyan}$ID${nc}"
	echo -e "-----------------------------------------------------------------------"
    echo -e "  Esecuzione con:"
    echo -e "             Command                  -> ${bcyan}$COMMAND${nc}"
    echo -e "             Mode                     -> $MODE"
    echo -e "             Environment              -> $ENVIRONMENT"
    if [[ ($STANDALONE = "true") ]]; then
	    echo -e "             Debug                    -> $DEBUG"
	    echo -e "             Jboss Hostname           -> $JBOSS_HOSTNAME"
	    echo -e "             Jboss Port               -> $JBOSS_PORT"
	fi
	echo -e "             Sonar Analysis           -> $CSONAR"
	echo -e "-----------------------------------------------------------------------"
}

function load_from_template { 
    mvn process-resources -Pchangelog -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true
	mvn process-resources -pl war -Pversions -Dhost_path=$host_path
}

function start_service {
	      
    if [ $BUILD = "true" ]; then
	   build
    fi
	
	docker rmi $(docker images | grep "^<none>" | awk "{print $3}") 2> /dev/null
   
    if [[ ($MODE = "PIPELINE") ]]; then
    	  docker/hostsUpdate.sh /etc/hosts | sponge /etc/hosts
	fi
	
	#docker-compose $DOCKER_COMPOSE_OPTIONS -f docker/$DOCKER_COMPOSE_FILE up -d swagger_ui_$SERVICE
	docker-compose $DOCKER_COMPOSE_OPTIONS -f docker/$DOCKER_COMPOSE_FILE up -d postgres_$SERVICE
	docker/wait-for-it.sh $POSTGRES_HOSTNAME:54${ID} -t 120
	
	if [[ ($STANDALONE = "true") ]]; then
      docker-compose $DOCKER_COMPOSE_OPTIONS -f docker/$DOCKER_COMPOSE_FILE up -d $SERVICE
    fi

    init_database

    if [[ ($MODE = "LOCAL") ]]; then
		docker-compose $DOCKER_COMPOSE_OPTIONS -f docker/$DOCKER_COMPOSE_FILE logs -f
    else
    	docker-compose $DOCKER_COMPOSE_OPTIONS -f docker/$DOCKER_COMPOSE_FILE logs
    	docker/wait-for-service.sh
    fi

}

function prepare {

  version $ENVIRONMENT $VERSION
  
  chmod +x docker/*.sh

  if [[ ($MODE = "LOCAL") ]]; then
	VERSION_SUFFIX="-SNAPSHOT"
  fi

  version=$(cat version)$VERSION_SUFFIX

  mvn versions:set -DnewVersion=$version -DoldVersion=*SNAPSHOT -DprocessAllModules=true -DgenerateBackupPoms=false
  
}

function build {

	prepare
	
    version=$(cat version)
    if [[ ($MODE = "PIPELINE") ]]; then
      load_from_template
      mvn clean install -DskipTests -Dhost_path=${host_path} -Djpa.skipTests -Dcheckstyle.skip -Djboss.skipDeploy=true
    else
# -- la versions:set viene già fatta nel 'prepare', questo si potrebbe togliere
      #mvn versions:set -DnewVersion=$version-SNAPSHOT
      load_from_template
      mvn clean install $OFFLINE -Plocal -Dhost_path=${host_path} -DskipTests -Dcheckstyle.skip -Djpa.skipTests -Djboss.skipDeploy=true
    fi
    
    if [ $? -ne 0 ]; then
	    exit 1
    fi
      		
	if [[ ($COMMAND = "build") ]]; then
	    exit 0
    fi
}

function deploy {
	
	if [[ ($STANDALONE = "false") ]]; then
		echo -e "\n\n-----------------------------------------------------------------------"
		echo -e " $SERVICE non è un servizio standalone e non può essere rilasciato"
		echo -e "-----------------------------------------------------------------------"
		exit 0
    fi
    

    if [ $BUILD = "true" ]; then
    	load_from_template
        mvn clean install $OFFLINE -Dhost_path=${host_path} -DskipTests -Dcheckstyle.skip -DskipITs -DPIPELINE=$PIPELINE -DLOCAL=$LOCAL -Djboss.hostname=$JBOSS_HOSTNAME -Djboss.port=$JBOSS_PORT -Djboss.username=$JBOSS_DEPLOYER_USERNAME -Djboss.password=$JBOSS_DEPLOYER_PASSWORD
    else
    	load_from_template
        mvn clean install $OFFLINE -Dhost_path=${host_path} -DskipTests -Dcheckstyle.skip -DskipITs -DPIPELINE=$PIPELINE -DLOCAL=$LOCAL -Djboss.hostname=$JBOSS_HOSTNAME -Djboss.port=$JBOSS_PORT -Djboss.username=$JBOSS_DEPLOYER_USERNAME -Djboss.password=$JBOSS_DEPLOYER_PASSWORD
    fi
    
 	if [ $? -ne 0 ]; then
        exit 1
    fi
}

ascii

PWD=`pwd`
export DEBUG="false"
export BUILD="true"
export MODE="LOCAL"
export LOCAL="false"
export PIPELINE="false"
export PRODUCTION="false"
export JBOSS_HOSTNAME="localhost"
export JBOSS_PORT="99${ID}"
export JBOSS_DEPLOYER_USERNAME="cdp"
export JBOSS_DEPLOYER_PASSWORD="cdp"
export JBOSS_SERVER_GROUP="main-server-group"
export POSTGRES_HOSTNAME="localhost"
export DOCKER_COMPOSE_FILE="docker-compose.yml"
export DOCKER_COMPOSE_OPTIONS="-p galileo"
export ENVIRONMENT="local"
export STANDALONE="true"
export SONAR="false"
export OFFLINE="-o"
export ORIG_MAVEN_OPTS=$MAVEN_OPTS

# Colors
red='\033[0;31m'
bred='\033[1;31m'
green='\033[0;32m'
bgreen='\033[1;32m'
yellow='\033[0;33m'
byellow='\033[1;33m'
cyan='\033[0;36m'
bcyan='\033[1;36m'

nc='\033[0m'

export SERVICE_UPPER=$(echo "$SERVICE" | tr '[:lower:]' '[:upper:]' | tr _ -)

unset $VERSION

for i in "$@"
do
case $i in
	start|start-int|stop|restart|test|build|deploy|prepare)
	COMMAND=$i
	shift
    ;;
    -m*|--mode*)
    set -- "$i" 
    IFS="="; declare -a Array=($*)
    MODE=${Array[1]}
    shift
    ;;
    -t*|--tag*)
    set -- "$i" 
    IFS="="; declare -a Array=($*)
    DOCKER_TAG=${Array[1]}
    shift
    ;;
    -d*|--debug*)
    export DEBUG="true"
    shift
    ;;
    -sb*|--skip-build*)
    export BUILD="false"
    shift
    ;;
    -U*|--update*)
    export OFFLINE="-U"
    shift
    ;;
    -st=*|--standalone*)
    set -- "$i" 
    IFS="="; declare -a Array=($*)
    STANDALONE="true"
    shift
    ;;
    -S|--sonar)
    export SONAR="true"
    shift
    ;;
    -e*|--env*)
    set -- "$i" 
    IFS='='; declare -a Array=($*)
    export ENVIRONMENT=${Array[1]}
    shift
    ;;
    -v=*|--version=*)
    set -- "$i" 
    IFS='='; arrIn=($*); unset IFS;
    version $ENVIRONMENT ${arrIn[1]}
    shift
    ;;
esac
done

[[ $SONAR == "true" ]] && export CSONAR="${bgreen}$SONAR${nc}" || export CSONAR="${bred}$SONAR${nc}"

if [[ (-z "$DOCKER_TAG") ]]; then
    export DOCKER_TAG=local
fi

if [[ (-z "$COMMAND") ]]; then
    usage
    print_env
    exit 0
fi

if [[ ($MODE = "LOCAL") ]]; then
    export LOCAL="true"
    export per_ws_host_name="localhost"
    export per_ws_host_port="8097"
    export per_ws_host_secure_port="8443"
    export per_ws_host_uri_scheme="http"
    export host_path="http://localhost:80"$ID
    
fi


if [[ ($MODE = "PIPELINE") ]]; then
    export PIPELINE="true"
    export DOCKER_COMPOSE_FILE="docker-compose.yml"
    export JBOSS_HOSTNAME="docker"
    export POSTGRES_HOSTNAME="docker"
    export per_ws_host_name="docker"
    export per_ws_host_port="8097"
    export per_ws_host_secure_port="8443"
    export per_ws_host_uri_scheme="http"
    
    unset OFFLINE
fi

if [[ ($MODE = "PRODUCTION") ]]; then
    export PRODUCTION="true"
fi

print_env

if [[ ($COMMAND = "restart") || ($COMMAND = "stop") ]]; then
	docker-compose $DOCKER_COMPOSE_OPTIONS -f docker/$DOCKER_COMPOSE_FILE down -v
fi

if [[ ($COMMAND = "stop") ]]; then
	exit 0
fi

if [[ ($COMMAND = "build") ]]; then
    build
fi

if [[ ($COMMAND = "prepare") ]]; then
    prepare
fi

if [[ ($COMMAND = "test") ]]; then
	
	if [[ ($STANDALONE = "true") ]]; then
	
	  if [[ ($MODE = "PIPELINE")  ]]; then
		start_service
	  fi
	  
    fi
    
    if [[ ($SONAR = "true") ]]; then 	
        mvn clean verify -U -PskipDeploy -Psonar sonar:sonar -Dcheckstyle.skip  -DPIPELINE=$PIPELINE -DLOCAL=$LOCAL -Djboss.hostname=$JBOSS_HOSTNAME -Djboss.port=99$ID -Dmqprop.hostName=192.168.3.13 -Dmqprop.queueManager=MQ02 -Dmqprop.channel=DMG.TO.MQ02 -Dmqprop.username="" -Dmqprop.password="" -Dmqprop.useJNDI=false -Ddatabase.hostname=$POSTGRES_HOSTNAME -Ddatabase.port=5497 -Ddatabase.name=gateway -Ddatabase.username=postgres -Ddatabase.password=postgres -Ddatabase.connection.url=jdbc:postgresql:// -Ddatabase.jdbc.driver=org.postgresql.Driver
    else
        mvn clean verify -U -PskipDeploy -Dcheckstyle.skip -DPIPELINE=$PIPELINE -DLOCAL=$LOCAL -Djboss.hostname=$JBOSS_HOSTNAME -Djboss.port=99$ID -Dmqprop.hostName=192.168.3.13 -Dmqprop.queueManager=MQ02 -Dmqprop.channel=DMG.TO.MQ02 -Dmqprop.username="" -Dmqprop.password="" -Dmqprop.useJNDI=false -Ddatabase.hostname=$POSTGRES_HOSTNAME -Ddatabase.port=5497 -Ddatabase.name=gateway -Ddatabase.username=postgres -Ddatabase.password=postgres -Ddatabase.connection.url=jdbc:postgresql:// -Ddatabase.jdbc.driver=org.postgresql.Driver
    fi

    
    if [[ ($MODE = "PIPELINE") && ($? -ne 0) ]]; then
      docker-compose $DOCKER_COMPOSE_OPTIONS -f docker/$DOCKER_COMPOSE_FILE logs
	  exit 1
    fi

    if [[ ($MODE = "PIPELINE") ]]; then
      mvn deploy -DskipTests -Dcheckstyle.skip -Djboss.skipDeploy=true
    fi
fi

if [[ ($COMMAND = "deploy") ]]; then
    deploy
fi

if [[ ($COMMAND = "start") || ($COMMAND = "start-int") || ($COMMAND = "restart") ]]; then
	start_service
fi
