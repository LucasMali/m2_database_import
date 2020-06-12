#!/bin/bash

backup_local() {
  echo "Dumping local DB for backup"
  # Does backup directory exists?
  if [ ! -d $(pwd)/backups ]; then
    echo "Creating backup folder"
    mkdir -p $(pwd)/backups
  fi

  if [ -z "$LOCALDBPASS" ]; then
    mysqldump -h ${LOCALDBHOST} -u ${LOCALDBUSER} --single-transaction ${LOCALDB} | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip > $(pwd)/backups/local.sql.gz
  else
    mysqldump -h ${LOCALDBHOST} -u ${LOCALDBUSER} -p${LOCALDBPASS} --single-transaction ${LOCALDB} | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip > $(pwd)/backups/local.sql.gz
  fi
}

get_production_db() {
  echo "Obtaining production Databse from ${SSHIP}"
    if [ ! -d $(pwd)/incoming ]; then
      echo "Creating import folder"
      mkdir -p $(pwd)/incoming
    fi

    ssh ${SSHIP} "mysqldump -h ${REMOTEDBHOST} -u ${REMOTEDBUSER} -p${REMOTEDBPASS} --single-transaction ${REMOTEDB} | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip " > $(pwd)/incoming/${DBFILE}
}

import_db() {
  if test -f $(pwd)/incoming/${DBFILE}; then
    echo "Importing production DB into local"
    if [ -z "$LOCALDBPASS" ]; then
      pv $(pwd)/incoming/${DBFILE} | zcat | mysql -h ${LOCALDBHOST} -u ${LOCALDBUSER} ${LOCALDB}
    else
      pv $(pwd)/incoming/${DBFILE} | zcat | mysql -h ${LOCALDBHOST} -u ${LOCALDBUSER} -p${LOCALDBPASS} ${LOCALDB}
    fi
  fi
}

clean_up_env() {
  echo "Cleaning up cached files"
  rm -fR ${WEB_ROOT}generated/code ${WEB_ROOT}generated/metadata ${WEB_ROOT}var/cache ${WEB_ROOT}var/view_preprocessed
}

update_config() {
  echo "Running magento commands to make sure configurations are correct."
  php ${WEB_ROOT}bin/magento app:config:import

  if [ ! -z "$FIRSTRUN" ] && [ "$FIRSTRUN" == true ]; then
    . update_config.sh || echo "Could not load the update config scripts"
  fi

  if [ ! -z "$ISLOCALENV" ]; then
    php ${WEB_ROOT}bin/magento admin:user:create \
        --admin-password="${ADMIN_PASS}" \
        --admin-user="${ADMIN_USER}" \
        --admin-firstname="Local" \
        --admin-lastname="Admin" \
        --admin-email="${ADMIN_EMAIL}"
    printf "u: %s\np: %s\n" "${ADMIN_USER}" "${ADMIN_PASS}"
  fi
}

load_config() {
  echo "getting configuration"
  # Load up .env
  set -o allexport
  [[ -f .env ]] && source .env
  set +o allexport
}

build_static_files() {
  echo "Building static files"
  STR=$(php ${WEB_ROOT}bin/magento deploy:mode:show)
  SUB="developer"
  if [[ "$STR" =~ .*"$SUB".* ]]; then
    php ${WEB_ROOT}bin/magento dev:source-theme:deploy
  else
    php ${WEB_ROOT}bin/magento setup:static-content:deploy
  fi
}

recompile (){
  php ${WEB_ROOT}bin/magento s:up
  php ${WEB_ROOT}bin/magento setup:di:compile
  php ${WEB_ROOT}bin/magento indexer:reindex
}

# The script starts here
cd $(dirname $(realpath ${BASH_SOURCE[0]}))
load_config
backup_local
get_production_db
import_db
clean_up_env
update_config
build_static_files
recompile
