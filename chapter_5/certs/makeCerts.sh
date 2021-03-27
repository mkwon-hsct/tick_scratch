# Create CA certificate
openssl genrsa 2048 > ca-key.pem
openssl req -new -x509 -nodes -days 3600 \
    -key ca-key.pem -out ca.pem -extensions usr_cert \
    -subj '/C=US/ST=New York/L=Brooklyn/O=Example Brooklyn Company/CN=examplebrooklyn.com'

# Create server certificate, remove passphrase, and sign it
# server-public.pem = public key, server-private.pem = private key
openssl req -newkey rsa:2048 -days 3600 -nodes \
    -keyout server-private.pem -out server-req.pem -extensions usr_cert \
    -subj '/C=JP/ST=Tokyo/L=Narimasu/O=Immanuel Company/CN=goldencity.com'
#openssl rsa -in server-key.pem -out server-key.pem
openssl x509 -req -in server-req.pem -days 3600 -CA ca.pem -CAkey ca-key.pem \
    -set_serial 01 -out server-public.pem -extensions usr_cert

# Create client certificate, remove passphrase, and sign it
# client-public.pem = public key, client-private.pem = private key
openssl req -newkey rsa:2048 -days 3600  -nodes \
    -keyout client-private.pem -out client-req.pem -extensions usr_cert \
    -subj '/C=JP/ST=Tokyo/L=Narimasu/O=Immanuel Company/CN=goldencity.com'
#openssl rsa -in client-private.pem -out client-private.pem
openssl x509 -req -in client-req.pem -days 3600 -CA ca.pem -CAkey ca-key.pem \
    -set_serial 01 -out client-public.pem -extensions usr_cert
