#!/bin/bash

function set_payment_sandbox(){
  # DEFAULT
  if [ ! -z ${PAYMENT} ] && [ ${PAYMENT} == 'square' ]; then
    CMD=squareup_omni/general/application_mode
  fi

  echo "Setting global payment to sandbox"
  php ${WEB_ROOT}bin/magento config:set --lock-env ${CMD} sandbox

  for CODE in "${WEBSITES[@]}"
  do
      echo "Payment is being set to sandbox for website ${CODE}"
      php ${WEB_ROOT}bin/magento config:set --lock-env --scope=websites --scope-code=${CODE} ${CMD} sandbox
  done

  for CODE in "${STORE[@]}"
  do
      echo "Payment is being set to sandbox for store ${CODE}"
      php ${WEB_ROOT}bin/magento config:set --lock-env --scope=stores --scope-code=${CODE} ${CMD} sandbox
  done
}

function set_no_emails(){
  echo "Disabling emails"
  php ${WEB_ROOT}bin/magento config:set --lock-env system/smtp/disable 1
}

function set_website_and_store_urls(){
  php ${WEB_ROOT}bin/magento config:set --lock-env web/cookie/cookie_domain ${MAINDOMAIN}
  ACC=0
  for CODE in "${STORES[@]}"
  do 
    HTTPS=${HTTPSLIST[${ACC}]}
    HTTP=${HTTPLIST[${ACC}]}
    DOMAIN=${DOMAINS[${ACC}]}
    echo "Store ${CODE} URLs are ${HTTPS} ${HTTP}"
    php ${WEB_ROOT}bin/magento config:set --lock-env --scope=store --scope-code=${CODE} web/secure/base_url "${HTTPS}"
    php ${WEB_ROOT}bin/magento config:set --lock-env --scope=store --scope-code=${CODE} web/unsecure/base_url "${HTTP}"
    php ${WEB_ROOT}bin/magento config:set --lock-env --scope=store --scope-code=${CODE} web/secure/base_link_url "{{secure_base_url}}"
    php ${WEB_ROOT}bin/magento config:set --lock-env --scope=store --scope-code=${CODE} web/unsecure/base_link_url "{{unsecure_base_url}}"
    echo "Setting cookie domain ${DOMAIN}"
    php ${WEB_ROOT}bin/magento config:set --lock-env --scope=store --scope-code=${CODE} web/cookie/cookie_domain ${DOMAIN}
    ACC=$((ACC+1))
  done
}

function no_security() {
    echo "Disabling 2FA"
    php ${WEB_ROOT}bin/magento config:set --lock-env msp_securitysuite_twofactorauth/general/enabled 0
    echo "Disabling recaptcha"
    php ${WEB_ROOT}bin/magento config:set --lock-env msp_securitysuite_recaptcha/backend/enabled  0
}

function sign_static() {
  echo "Turning off signed public static files."
    php ${WEB_ROOT}bin/magento config:set --lock-env dev/static/sign 0
}

function secure_url() {
  VAL=0
  echo ${SECUREURLS}
  if [ ! -z ${SECUREURLS} ] && [ ${SECUREURLS} == "true" ]; then
    VAL=1
  fi
    echo "Setting use of secure URLS to ${VAL}"

  php ${WEB_ROOT}bin/magento config:set --lock-env web/secure/use_in_adminhtml $VAL
  php ${WEB_ROOT}bin/magento config:set --lock-env web/secure/use_in_frontend $VAL
}

set_payment_sandbox
set_no_emails
set_website_and_store_urls
no_security
# sign_static
secure_url