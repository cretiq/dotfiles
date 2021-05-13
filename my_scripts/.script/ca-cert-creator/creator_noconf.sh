#!/usr/bin/env bash
sudo openssl genrsa -out localhost.key 2048 &&
sudo openssl rsa -in localhost.key -out localhost.key.rsa &&
sudo openssl req -new -key localhost.key.rsa -subj /CN=localhost -out localhost.csr &&
sudo openssl x509 -req -extensions v3_req -days 3650 -in localhost.csr -signkey localhost.key.rsa -out localhost.crt &&
sudo chmod 775 localhost.key