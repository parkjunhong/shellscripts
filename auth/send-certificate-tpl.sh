#!/usr/bin/env bash

NO_SEND=0
NO_DELETE=0

while [ ! -z "$1" ];
do
  case "$1" in
    --no-send)
      NO_SEND=1
      ;;
    --no-delete)
      NO_DELETE=1
      ;;
    -h|--help)
      echo
      echo "'--no-send' for DO NOT send file to destination."
      echo "'--no-delete' for DO NOT delete converted files, e.g. ssl, pkcs12, ..)"
      echo
      exit 0
      ;;
    *)
      ;;
  esac
  shift
done

SSH_PRI_KEY="..."
CERT_DIR="..."
SSL_CA_DIR="..."
PKCS12_DIR="..."
JKS_DIR="..."

PEM_DESTS=( ... )
SSL_CA_DESTS=( ... )
PKCS12_DESTS=( ... )
JKS_DESTS=( ... )
CERT_NAME="..."
P12_PWD="..."
NAME_OR_ALIAS="..."
INTER_CERTS_ALIAS_OR_CNAME="intermediate"
ROOT_CERTS_ALIAS="isrg-root-x1"

validate-file(){
  if [ ! -f "$1" ];then
    echo " ❌❌❌ Invalid certificated file: $1" $LINENO
    exit 1
  else
    echo " * * * Validated file: $1"
  fi
}

## pem to '.crt' & '.key'
conver-pem-to-sslca(){
  echo
  echo " ✅  > > > begin: convert to nginx ssl & ca "
  
  # 1. clear old files.
  rm -rf $SSL_CA_DIR
  mkdir $SSL_CA_DIR

  #2. create a crt file
  openssl x509 -inform PEM -in "$FILE_FULLCHAIN"  -out "$SSL_CA_DIR/${CERT_NAME}.crt"

  #3. create a key file
  printf " * * * "
  openssl rsa -in "$FILE_PRIVKEY" -text > "$SSL_CA_DIR/${CERT_NAME}.key"

  #4. list crt & key
  echo
  ls -al $SSL_CA_DIR/

  echo " < < < end:"
}

## pem to '.p12'
conver-pem-to-p12(){
  echo
  echo " ✅> > > > begin: convert to pkcs12"

  #1. clear old files.
  rm -rf $PKCS12_DIR
  mkdir $PKCS12_DIR
  #openssl pkcs12 -export -out "${PKCS12_DIR}/${CERT_NAME}.p12" -passout pass:$P12_PWD -in "$FILE_CERT" -inkey "$FILE_PRIVKEY" -CAfile "$FILE_FULLCHAIN" -name "$NAME_OR_ALIAS"
  openssl pkcs12 -export -out "${PKCS12_DIR}/${CERT_NAME}.p12" -passout pass:$P12_PWD -in "$FILE_FULLCHAIN" -inkey "$FILE_PRIVKEY" -CAfile "$FILE_CHAIN" -caname "$INTER_CERTS_ALIAS_OR_CNAME" -name "$NAME_OR_ALIAS" 
  ls -al "${PKCS12_DIR}/${CERT_NAME}.p12"

  echo " < < < end:"
}

## pem to '.p12' to '.jks'. (Java KeyStore)
## use p12 (pkck12) files.
# @since: 2024/10/30
convert-p12-to-jks(){
  echo
  echo " ✅ > > > bewgin: conver to jks"

  #1. check '.p12' file
  if [ ! -f "${PKCS12_DIR}/${CERT_NAME}.p12" ];then
    echo
    echo " ❌❌❌ No file for PKCS12. Path=${PKCS12_DIR}/${CERT_NAME}.p12"
  else 
    #2. clear old files
    rm -rf $JKS_DIR
    mkdir $JKS_DIR
    echo " + ✅  'p12' -> 'jks'" 
    keytool -importkeystore -deststorepass "$P12_PWD" -destkeypass "$P12_PWD" -destkeystore "${JKS_DIR}/${CERT_NAME}.jks" -srckeystore "${PKCS12_DIR}/${CERT_NAME}.p12" -srcstoretype PKCS12 -srcstorepass "$P12_PWD" -alias "$NAME_OR_ALIAS"
    echo " + ✅ inject 'intermediate CA'"
    keytool -import -trustcacerts -file "$FILE_CHAIN" -keystore "${JKS_DIR}/${CERT_NAME}.jks" -storepass "$P12_PWD" -alias "$INTER_CERTS_ALIAS_OR_CNAME" -noprompt
    echo " + ✅ inject 'ROOT CA'"
    keytool -import -trustcacerts -file "$FILE_ROOT" -keystore "${JKS_DIR}/${CERT_NAME}.jks" -storepass "$P12_PWD" -alias "$ROOT_CERTS_ALIAS" -noprompt 
  fi
  ls -al "${JKS_DIR}/${CERT_NAME}.jks"

  echo " < < < end:"
}

## send file to destnation
# @param $1 {string} directory contains converted files
# @param $2 {string} directory which is target server.
# @since 2024/10/30
send-files(){
  if [ $# -ne 2 ];then
    echo
    echo " ❌❌❌ Illegal arguments."
  else
    local srcDir="$1"
    local dstDir="$2"
    echo "scp -i $SSH_PRI_KEY $srcDir/*.* $dstDir"
    if [ $NO_SEND -eq 1 ];then
      echo " ❗❗❗ DO NOT send files because enables 'NO_SEND'."
    else
      scp -i $SSH_PRI_KEY $srcDir/*.* $dstDir
    fi
  fi
}

##
## remove directory recursively.
# @param $1 {string}: directory path.
# @since: 2024/10/30
delete-dir(){
  echo "rm -rf $1"
  if [ $NO_DELETE -eq 1 ];then
    echo " ❗❗❗ DO NOT delete converted files because enables 'NO_DELETE'."
  else
    rm -rf "$1"
  fi
}


if [ ! -d "$CERT_DIR" ];then
  echo " ❌❌❌ Invalid certificated files directory. path=$CERT_DIR"
fi

echo
## Validate certificated files.
validate-file "$CERT_DIR/cert1.pem"
validate-file "$CERT_DIR/chain1.pem"
validate-file "$CERT_DIR/fullchain1.pem"
validate-file "$CERT_DIR/privkey1.pem"

FILE_CERT="$CERT_DIR/cert1.pem"
FILE_CHAIN="$CERT_DIR/chain1.pem"
FILE_FULLCHAIN="$CERT_DIR/fullchain1.pem"
FILE_PRIVKEY="$CERT_DIR/privkey1.pem"
FILE_ROOT="$CERT_DIR/${ROOT_CERTS_ALIAS}.pem"

echo
echo " ✅ > > > download 'ISRG ROOT CACERTS file"
wget -q https://letsencrypt.org/certs/isrgrootx1.pem -O "$FILE_ROOT"

echo
# convert pem files for nginx
conver-pem-to-sslca

echo
# convert pem files for springboot
conver-pem-to-p12

echo
# convert pem files for jks (Java KeyStore)
# @since: 2024/10/30
convert-p12-to-jks

# send pem files to destinations
echo
echo " ✅ > > > begin: send certificates"
for dst in ${PEM_DESTS[@]};
do
  send-files "$CERT_DIR" "$dst"
  echo "---"
done
echo " < < < end:"

# send to 'ssl & ca' server.
echo
echo " ✅ > > > begin: send ssl & ca"
for dst in ${SSL_CA_DESTS[@]};
do
  send-files "$SSL_CA_DIR" "$dst"
  echo "---"
done
echo " < < < end:"

# send to 'pkcs12' server.
echo
echo " ✅ > > > begin: send pkcs12"
for dst in ${PKCS12_DESTS[@]};
do
  send-files "$PKCS12_DIR" "$dst"
  echo "---"
done
echo " < < < end:"

# send to 'jks' server.
echo
echo " ✅ > > > begin: send jks"
for dst in ${JKS_DESTS[@]};
do
  send-files "$JKS_DIR" "$dst"
  echo "---"
done
echo " < < < end:"

# clear directory
echo
delete-dir "$SSL_CA_DIR"
delete-dir "$PKCS12_DIR"
delete-dir "$JKS_DIR"
# 'delete' isrg-root-x1
rm -rf $FILE_ROOT

echo
exit 0


