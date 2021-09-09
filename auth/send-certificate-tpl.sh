#!/usr/bin/env bash

# source directories
CERT_DIR="..."
SSL_CA_DIR="..."
PKCS12_DIR="..."

# destination directories
# pattern: {account}@{host}:{fuallpath} 
PEM_DESTS=( ... )
SSL_CA_DESTS=( ... )
PKCS12_DESTS=( ... )

# R3-wildcar file name
CERT_NAME="..."
# password for P12
P12_PWD="..."

validate-file(){
	if [ ! -f "$1" ];then
		echo " ! ! ! Invalid certificated file: $1" $LINENO
		exit 1
	else
		echo " * * * Validated file: $1"
	fi
}

##
convert-to-sslca(){
	echo
	echo " > > > begin: convert to nginx ssl & ca "
	
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

##
convert-to-p12(){
	echo
	echo " > > > begin: convert to pkcs12"

	#1. clear old files.
	rm -rf $PKCS12_DIR
	mkdir $PKCS12_DIR
	openssl pkcs12 -export -out "${PKCS12_DIR}/${CERT_NAME}.p12" -passout pass:$P12_PWD -in "$FILE_CERT" -inkey "$FILE_PRIVKEY" -CAfile "$FILE_FULLCHAIN" -name ymtech
	ls -al "${PKCS12_DIR}/${CERT_NAME}.p12"

	echo " < < < end:"
}

if [ ! -d "$CERT_DIR" ];then
	echo " ! ! ! Invalid certificated files directory. path=$CERT_DIR"
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

echo
# convert pem files for nginx
convert-to-sslca

echo
# convert pem files for springboot
convert-to-p12

# send pem files to destinations
echo
echo " > > > begin: send certificates"
for dst in ${PEM_DESTS[@]};
do
	echo "scp $CERT_DIR/*.* $dst"
	scp $CERT_DIR/*.* $dst
	echo "---"
done
echo " < < < end:"

# send to 'ssl & ca' server.
echo
echo " > > > begin: send ssl & ca"
for dst in ${SSL_CA_DESTS[@]};
do
	echo "scp $SSL_CA_DIR/*.* $dst"
	scp $SSL_CA_DIR/*.* $dst
	echo "---"
done
echo " < < < end:"
# clear directory
echo
echo "rm -rf $SSL_CA_DIR"
rm -rf $SSL_CA_DIR

# send to 'pkcs12' server.
echo
echo " > > > begin: send pkcs12"
for dst in ${PKCS12_DESTS[@]};
do
	echo "scp $PKCS12_DIR/*.* $dst"
	scp $PKCS12_DIR/*.* $dst
	echo "---"
done
echo " < < < end:"
# clear directory
echo
echo "rm -rf $PKCS12_DIR"
rm -rf $PKCS12_DIR

echo
exit 0


