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
  ACC=0
  for CODE in "${STORES[@]}"
  do 
    HTTPS=${HTTPSLIST[${ACC}]}
    HTTP=${HTTPLIST[${ACC}]}
    echo "Store ${CODE} URLs are ${HTTPS} ${HTTP}"
    php ${WEB_ROOT}bin/magento config:set --lock-env --scope=store --scope-code=${CODE} web/secure/base_url "${HTTPS}"
    php ${WEB_ROOT}bin/magento config:set --lock-env --scope=store --scope-code=${CODE} web/unsecure/base_url "${HTTP}"
    php ${WEB_ROOT}bin/magento config:set --lock-env --scope=store --scope-code=${CODE} web/secure/base_link_url "{{secure_base_url}}"
    php ${WEB_ROOT}bin/magento config:set --lock-env --scope=store --scope-code=${CODE} web/unsecure/base_link_url "{{unsecure_base_url}}"
    ACC=$((ACC+1))
  done
}

function no_security() {
    echo "Disabling 2FA"
    php ${WEB_ROOT}bin/magento config:set --lock-env msp_securitysuite_twofactorauth/general/enabled 0
    # php ${WEB_ROOT}bin/magento config:set --lock-env web/cookie/cookie_domain ${MAINDOMAIN}
    echo "Disabling recaptcha"
    php ${WEB_ROOT}bin/magento config:set --lock-env msp_securitysuite_recaptcha/backend/enabled  0
}

set_payment_sandbox
set_no_emails
set_website_and_store_urls
no_security