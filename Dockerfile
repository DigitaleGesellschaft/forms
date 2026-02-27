# syntax=docker/dockerfile:1

# start from official Formbricks image
FROM ghcr.io/formbricks/formbricks:4.7.5

# copy aiven.io's private CA cert
COPY --link aiven.io_ca.pem /aiven.io_ca.pem
